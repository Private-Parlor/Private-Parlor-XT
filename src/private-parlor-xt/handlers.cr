require "tourmaline"

module PrivateParlorXT
  annotation RespondsTo
  end

  annotation On
  end

  annotation Hears
  end

  abstract class Handler
    abstract def initialize(config : Config)

    abstract def do(context : Context, services : Services)

    def update_user_activity(user : User, services : Services)
      user.set_active
      services.database.update_user(user)
    end

    def get_reply_message(user : User, message : Tourmaline::Message, services : Services) : Tourmaline::Message?
      unless message.reply_to_message
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.no_reply)
        return
      end

      message.reply_to_message
    end

    def get_reply_user(user : User, reply_message : Tourmaline::Message, services : Services) : User?
      reply_user_id = services.history.get_sender(reply_message.message_id.to_i64)

      reply_user = services.database.get_user(reply_user_id)
      
      unless reply_user
        services.relay.send_to_user(reply_message.message_id.to_i64, user.id, services.locale.replies.not_in_cache)
        return
      end

      reply_user
    end
  end

  abstract class CommandHandler < Handler
    def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, services)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, services : Services) : Nil
      return unless user.blacklisted?
      
      response = Format.substitute_message(services.locale.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.locale),
        "reason"  => Format.format_reason_reply(user.blacklist_reason, services.locale),
      })

      services.relay.send_to_user(nil, user.id, response)
    end

    def is_authorized?(user : User, message : Tourmaline::Message, permission : CommandPermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, permission)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.command_disabled)
        return false
      end

      true
    end

    def is_authorized?(user : User, message : Tourmaline::Message, services : Services, *permissions : CommandPermissions) : CommandPermissions?
      if authority = services.access.authorized?(user.rank, *permissions)
        authority
      else
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.command_disabled)
      end
    end

    def delete_messages(message : MessageID, user : UserID, debug_enabled : Bool?, priority : Bool, services : Services) : MessageID?
      if reply_msids = services.history.get_all_receivers(message)
        unless debug_enabled
          reply_msids.delete(user)
        end

        if priority
          reply_msids.each do |receiver, receiver_message|
            services.relay.delete_message(receiver, receiver_message)
          end
        else
          reply_msids.each do |receiver, receiver_message|
            services.relay.remove_message(receiver, receiver_message)
          end
        end

        services.history.delete_message_group(message)
      end
    end
  end

  abstract class UpdateHandler < Handler
    def get_message_and_user(update : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = update.message) && (info = message.from)
        return nil, nil
      end

      if text = message.text
        return nil, nil if text.starts_with?('/')
        return nil, nil if text.starts_with?(/^[+-]1/)
      end

      unless user = services.database.get_user(info.id.to_i64)
        services. relay.send_to_user(nil, info.id.to_i64, services.locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_chat?(services.config.media_limit_period)
        deny_user(user, services)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    def is_authorized?(user : User, message : Tourmaline::Message, authority : MessagePermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, authority)
        response = Format.substitute_message(services.locale.replies.media_disabled, {"type" => authority.to_s})
        services.relay.send_to_user(message.message_id.to_i64, user.id, response)
        return false
      end

      true
    end

    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_date
      return false if message.media_group_id

      return true
    end

    private def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_message(services.locale.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.locale),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, services.locale),
        })
      elsif cooldown_until = user.cooldown_until
        response = Format.substitute_message(services.locale.replies.on_cooldown, {
          "time" => Format.format_time(cooldown_until, services.locale.time_format),
        })
      elsif Time.utc - user.joined < services.config.media_limit_period
        response = Format.substitute_message(services.locale.replies.media_limit, {
          "total" => (services.config.media_limit_period - (Time.utc - user.joined)).hours.to_s,
        })
      else
        response = services.locale.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end

    def check_text(text : String?, user : User, message : Tourmaline::Message, services : Services) : Bool
      return true unless text

      return true if message.preformatted?

      unless Format.allow_text?(text)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.rejected_message)
        return false
      end

      true
    end

    def format_text(text : String?, entities : Array(Tourmaline::MessageEntity), preformatted : Bool?, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      unless text
        return "", [] of Tourmaline::MessageEntity
      end

      unless preformatted
        text, entities = Format.strip_format(text, entities, services.config.entity_types, services.config.linked_network)
      end

      return text, entities
    end

    def get_reply_receivers(reply : Tourmaline::Message, message : Tourmaline::Message, user : User, services : Services) : Hash(UserID, MessageID)?
      replies = services.history.get_all_receivers(reply.message_id.to_i64)
      
      if replies.empty?
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.not_in_cache)
        return
      end

      replies
    end

    def get_message_receivers(user : User, services : Services) : Array(UserID)
      if user.debug_enabled
        services.database.get_active_users
      else
        services.database.get_active_users(user.id)
      end
    end

  end

  abstract class HearsHandler < Handler
    def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.locale.replies.not_in_chat)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_message(services.locale.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.locale),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, services.locale),
        })
      else
        response = services.locale.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end
