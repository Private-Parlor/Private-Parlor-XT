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

      unless user.can_chat?(services.config.media_limit_period)
        deny_user(user, services)
        return message, nil
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

    def check_text(text : String?, user : User, message : Tourmaline::Message, services : Services) : Bool
      return true unless text

      return true if message.preformatted?

      if r9k = services.robot9000
        unless r9k.allow_text?(text)
          services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.rejected_message)
          return false
        end
      else
        unless Format.allow_text?(text)
          services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.rejected_message)
          return false
        end
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

    def prepend_pseudonym(text : String, entities : Array(Tourmaline::MessageEntity), user : User, message : Tourmaline::Message, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      unless services.config.pseudonymous
        return text, entities
      end

      if message.preformatted?
        return text, entities
      end

      unless tripcode = user.tripcode
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.no_tripcode_set)
        return "", [] of Tourmaline::MessageEntity
      end

      name, tripcode = Format.generate_tripcode(tripcode, services.config.tripcode_salt)
      header, entities = Format.format_tripcode_sign(name, tripcode, entities)

      return header + text, entities
    end

    def get_caption_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      if (caption = message.caption) && message.preformatted?
        return caption, message.caption_entities
      end

      caption = message.caption || ""

      unless check_text(caption, user, message, services)
        return "", [] of Tourmaline::MessageEntity
      end

      caption, entities = format_text(caption, message.caption_entities, message.preformatted?, services)

      caption, entities = prepend_pseudonym(caption, entities, user, message, services)

      return caption, entities
    end

    def r9k_checks(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless r9k_text(user, message, services)
      return false unless r9k_media(user, message, services)

      true
    end

    def r9k_forward_checks(user : User, message : Tourmaline::Message, services : Services) : Bool
      return true unless r9k = services.robot9000
      return true unless r9k.check_forwards?

      return false unless r9k_text(user, message, services)
      return false unless r9k_media(user, message, services)

      true
    end

    def r9k_text(user : User, message : Tourmaline::Message, services : Services) : Bool
      unless (r9k = services.robot9000) && r9k.check_text?
        return true
      end

      text = message.text || message.caption || ""

      entities = message.caption_entities.empty? ? message.entities : message.caption_entities

      stripped_text = r9k.strip_text(text, entities)

      if r9k.unoriginal_text?(stripped_text)
        if r9k.cooldown > 0
          duration = user.cooldown(r9k.cooldown.seconds)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        elsif r9k.warn_user?
          duration = user.cooldown(services.config.cooldown_base)
          user.warn(services.config.warn_lifespan)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        else
          response = services.replies.unoriginal_message
        end

        services.relay.send_to_user(message.message_id.to_i64, user.id, response)

        return false
      end

      r9k.add_line(stripped_text)

      true
    end

    def r9k_media(user : User, message : Tourmaline::Message, services : Services) : Bool
      unless (r9k = services.robot9000) && r9k.check_media?
        return true
      end

      return false unless file_id = r9k.get_media_file_id(message)

      if r9k.unoriginal_media?(file_id)
        if r9k.cooldown > 0
          duration = user.cooldown(r9k.cooldown.seconds)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        elsif r9k.warn_user?
          duration = user.cooldown(services.config.cooldown_base)
          user.warn(services.config.warn_lifespan)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        else
          response = services.replies.unoriginal_message
        end

        services.relay.send_to_user(message.message_id.to_i64, user.id, response)

        return false
      end

      r9k.add_file_id(file_id)

      true
    end
  end
end