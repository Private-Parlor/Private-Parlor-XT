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

    abstract def do(ctx : Context, services : Services)

    def update_user_activity(user : User, services : Services)
      user.set_active
      services.database.update_user(user)
    end

    def is_authorized?(user : User, message : Tourmaline::Message, authority : CommandPermissions, services : Services,) : Bool
      unless services.access.authorized?(user.rank, authority)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.fail)
        return false
      end

      true
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

  abstract class CommandHandler
    @blacklist_contact : String? = nil

    abstract def initialize(config : Config)

    abstract def do(ctx : Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)

    private def get_message_and_user(ctx : Tourmaline::Context, database : Database, relay : Relay, locale : Locale) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = database.get_user(info.id.to_i64)
        relay.send_to_user(nil, info.id.to_i64, locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, relay, locale)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, relay : Relay, locale : Locale) : Nil
      return unless user.blacklisted?
      
      response = Format.substitute_message(locale.replies.blacklisted, locale, {
        "contact" => Format.format_contact_reply(@blacklist_contact, locale),
        "reason"  => Format.format_reason_reply(user.blacklist_reason, locale),
      })

      relay.send_to_user(nil, user.id, response)
    end
  end

  abstract class UpdateHandler
    @blacklist_contact : String? = nil
    @media_limit_period : Time::Span = 0.hours

    abstract def initialize(config : Config)

    abstract def do(update : Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)

    private def get_message_and_user(update : Tourmaline::Context, database : Database, relay : Relay, locale : Locale) : Tuple(Tourmaline::Message?, User?)
      unless (message = update.message) && (info = message.from)
        return nil, nil
      end

      unless user = database.get_user(info.id.to_i64)
        relay.send_to_user(nil, info.id.to_i64, locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_chat?(@media_limit_period)
        deny_user(user, relay, locale)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, relay : Relay, locale : Locale) : Nil
      if user.blacklisted?
        response = Format.substitute_message(locale.replies.blacklisted, locale, {
          "contact" => Format.format_contact_reply(@blacklist_contact, locale),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, locale),
        })
      elsif cooldown_until = user.cooldown_until
        response = Format.substitute_message(locale.replies.on_cooldown, locale, {
          "time" => Format.format_time(cooldown_until, locale.time_format),
        })
      elsif Time.utc - user.joined < @media_limit_period
        response = Format.substitute_message(locale.replies.media_limit, locale, {
          "total" => (@media_limit_period - (Time.utc - user.joined)).hours.to_s,
        })
      else
        response = locale.replies.not_in_chat
      end

      relay.send_to_user(nil, user.id, response)
    end

    private def check_text(text : String, user : User, message : Tourmaline::Message, entities : Array(Tourmaline::MessageEntity), relay : Relay, locale : Locale) : Tuple(String, Array(Tourmaline::MessageEntity))
      unless Format.allow_text?(text)
        relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.rejected_message)
        return "", [] of Tourmaline::MessageEntity
      end

      text, entities = Format.strip_format(text, entities, @entity_types, @linked_network)

      # TODO: Handle ranksay/sign/tsign/karmasign

      return text, entities
    end
  end

  abstract class HearsHandler < Handler
    abstract def initialize(config : Config)

    abstract def do(ctx : Context, services : Services)

    def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, locale.replies.not_in_chat)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_message(services.locale.replies.blacklisted, services.locale, {
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
