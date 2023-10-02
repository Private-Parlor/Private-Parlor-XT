require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  annotation On
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
        services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
        return message, nil
      end

      if text
        unless user.can_chat?
          deny_user(user, services)
          return message, nil
        end
      else
        unless user.can_chat?(services.config.media_limit_period)
          deny_user(user, services)
          return message, nil
        end
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    def authorized?(user : User, message : Tourmaline::Message, authority : MessagePermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, authority)
        response = Format.substitute_reply(services.replies.media_disabled, {"type" => authority.to_s})
        services.relay.send_to_user(message.message_id.to_i64, user.id, response)
        return false
      end

      true
    end

    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_date
      return false if message.media_group_id

      true
    end

    def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
        })
      elsif cooldown_until = user.cooldown_until
        response = Format.substitute_reply(services.replies.on_cooldown, {
          "time" => Format.format_time(cooldown_until, services.locale.time_format),
        })
      elsif Time.utc - user.joined < services.config.media_limit_period
        response = Format.substitute_reply(services.replies.media_limit, {
          "total" => (services.config.media_limit_period - (Time.utc - user.joined)).hours.to_s,
        })
      else
        response = services.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end

    def get_reply_receivers(reply : Tourmaline::Message, message : Tourmaline::Message, user : User, services : Services) : Hash(UserID, MessageID)?
      replies = services.history.get_all_receivers(reply.message_id.to_i64)

      if replies.empty?
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.not_in_cache)
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
end
