require "../handler.cr"
require "tourmaline"

module PrivateParlorXT
  # Annotation for Telegram update handlers
  #
  # ## Keys and Values:
  #
  # `update`
  # :     a member of `Tourmaline::UpdateAction`
  #
  # `config`
  # :     `String`, the name of the `Config` member that enables this handler.
  #       Handlers should be configurable, though a value is not required here to compile or be used in the program.
  annotation On
  end

  # A base class for handling one of the Telegram updates (`Tourmaline::Text`, `Tourmaline::Photo`, `Tourmaline::ForwardedMessage`, etc).
  #
  # Handlers that are meant to work with Telegram updates should inherit this class,
  # and include an `On` annotation to have it be usable by the bot.
  abstract class UpdateHandler < Handler
    # Returns the `User` associated with the message if the `User` could be found in the `Database`.
    # This will also update the `User`'s username and realname if they have changed since the last message.
    #
    # Returns `nil`  if:
    #   - Message has no sender
    #   - Message is a command
    #   - `User` does not exist in the `Database`
    #   - `User` cannot chat right now (due to a cooldown, blacklist, media limit, or having left the chat)
    def user_from_message(message : Tourmaline::Message, services : Services) : User?
      return unless info = message.from

      if text = message.text
        return_on_command(text)
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

    # Returns `true` if user is authorized to send this type of message (one of the `MessagePermissions` types).
    #
    # Returns `false` otherwise.
    def authorized?(user : User, message : Tourmaline::Message, authority : MessagePermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, authority)
        response = Format.substitute_reply(services.replies.media_disabled, {"type" => authority.to_s})
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
        return false
      end

      true
    end

    # Returns `true` if the *message* is not a forward or an album.
    #
    # Returns `false` otherwise.
    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_origin
      return false if message.media_group_id

      true
    end

    # Queues a system reply when the user cannot chat due to being either cooldowned, blacklisted, media limited, or left.
    def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.contact(services.config.blacklist_contact, services.replies),
          "reason"  => Format.reason(user.blacklist_reason, services.replies),
        })
      elsif cooldown_until = user.cooldown_until
        response = Format.substitute_reply(services.replies.on_cooldown, {
          "time" => Format.time(cooldown_until, services.locale.time_format),
        })
      elsif Time.utc - user.joined < services.config.media_limit_period
        response = Format.substitute_reply(services.replies.media_limit, {
          "total" => Format.time_span(services.config.media_limit_period - (Time.utc - user.joined), services.locale),
        })
      else
        response = services.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end

    # Returns a hash of a receiver's `UserID` to the relevant message ID for which this message will reply to when relayed.
    # When quoting, the `ReplyParameters` value will contain the replied message's quote if it is not invalid (i.e., user quoted his own message and it had strippable entities or was edited)
    #
    # The hash will be empty if the message does not have a reply
    #
    # Returns nil if the message had a reply, but no receiver message IDs could be found (message replied to is no longer in the cache)
    def reply_receivers(message : Tourmaline::Message, user : User, services : Services) : Hash(UserID, ReplyParameters)?
      return Hash(UserID, ReplyParameters).new unless reply = message.reply_to_message

      replies = services.history.receivers(reply.message_id.to_i64)

      if reply && replies.empty?
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cache)
      end

      quote = message.quote

      # This case checks if the user is trying to quote his own message
      # The quote must match the text exactly, including formatting, so only quote if:
      #   - the replied text does NOT contain entities that should be stripped
      #   - messsage was NOT edited
      if (from = reply.from) && from.id == user.id
        reply_entities = reply.entities.map(&.type)
        stripped_reply_entities = reply_entities - services.config.entity_types

        unless stripped_reply_entities == reply_entities && reply.edit_date == nil
          quote = nil
        end
      end

      if quote
        replies.transform_values do |val|
          ReplyParameters.new(
            message_id: val,
            quote: quote.text,
            quote_entities: quote.entities,
            quote_position: quote.position,
          )
        end
      else
        replies.transform_values do |val|
          ReplyParameters.new(val)
        end
      end
    end

    # Returns an array of `UserID` for which the relayed message will be sent to
    #
    # If the given *User* has debug mode enabled, he will get a copy of the relayed message
    def message_receivers(user : User, services : Services) : Array(UserID)
      if user.debug_enabled
        services.database.active_users
      else
        services.database.active_users(user.id)
      end
    end

    # If the statistics module is enabled, update the message_stats for the given *type* by incrementing the totals.
    def record_message_statistics(type : Statistics::Messages, services : Services) : Nil
      return unless stats = services.stats

      stats.increment_messages(type)
    end

    # Returns early if the message *text* contains a command.
    #
    # Iterates through all `HearsHandlers` that are meant to be commands,
    # and returns early if the handler matches a substring in the text (for `RegexLiteral` patterns)
    # or if the handler starts with a substring (for `StringLiteral` patterns)
    macro return_on_command(text)
      return if text.starts_with?('/')

      {% for hears_handler in HearsHandler.all_subclasses.select { |sub_class|
                                (hears = sub_class.annotation(Hears))
                              } %}

        {% hears = hears_handler.annotation(Hears) %}

        {% if hears[:command] && hears[:pattern].is_a?(RegexLiteral) %}
          return if text.matches?({{hears[:pattern]}})
        {% elsif hears[:command] && hears[:pattern].is_a?(StringLiteral) %}
          return if text.starts_with?({{hears[:pattern]}})
        {% end %}

      {% end %}
    end
  end
end
