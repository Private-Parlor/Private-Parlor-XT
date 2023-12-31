require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  annotation On
  end

  abstract class UpdateHandler < Handler
    def get_user_from_message(message : Tourmaline::Message, services : Services) : User?
      return unless info = message.from

      if text = message.text
        return if text.starts_with?('/') || text.starts_with?(/^[+-]1/)
      end

      unless user = services.database.get_user(info.id.to_i64)
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      if text
        return deny_user(user, services) unless user.can_chat?
      else
        return deny_user(user, services) unless user.can_chat?(services.config.media_limit_period)
      end

      user.update_names(info.username, info.full_name)

      user
    end

    def authorized?(user : User, message : Tourmaline::Message, authority : MessagePermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, authority)
        response = Format.substitute_reply(services.replies.media_disabled, {"type" => authority.to_s})
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
        return false
      end

      true
    end

    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_origin
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

    def get_reply_receivers(message : Tourmaline::Message, user : User, services : Services) : Hash(UserID, ReplyParameters)
      return Hash(UserID, ReplyParameters).new unless reply = message.reply_to_message

      replies = services.history.get_all_receivers(reply.message_id.to_i64)

      # These cases check if the user is trying to quote his own message
      # The quote must match the text exactly, including formatting, so only quote if: 
      #   the replied text does NOT contain entities that should be stripped 
      #   if messsage was NOT edited
      if (from = reply.from) && from.id == user.id
        unless (reply.entities.map(&.type) - services.config.entity_types) == reply.entities.map(&.type) && reply.edit_date == nil
          return replies.transform_values do |val|
            ReplyParameters.new(val)
          end
        end
      end

      quote = message.quote
      replies.transform_values do |val|
        if quote
          ReplyParameters.new(
            message_id: val,
            quote: quote.text,
            quote_entities: quote.entities,
            quote_position: quote.position,
          )
        else
          ReplyParameters.new(val)
        end
      end
    end

    def reply_exists?(message : Tourmaline::Message, replies : Hash(UserID, ReplyParameters), user : User, services : Services) : Bool?
      return true unless message.reply_to_message && replies.empty?
      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cache)
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
