require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Text, config: "relay_text")]
  class TextHandler < UpdateHandler
    @entity_types : Array(String)
    @linked_network : Hash(String, String) = {} of String => String

    def initialize(config : Config)
      @entity_types = config.entities
      @linked_network = config.linked_network
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Text)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "text"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      return if message.forward_date
      return unless text = message.text

      if spam && spam.spammy_text?(user.id, text)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      # TODO: Add R9K check hook

      text, entities = check_text(text, user, message, message.entities, relay, locale)
      return if text.empty?

      # TODO: Add pseudonymous hook

      new_message = history.new_message(user.id, message.message_id.to_i64)

      if reply = message.reply_to_message
        reply_msids = history.get_all_receivers(reply.message_id.to_i64)

        if reply_msids.empty?
          relay.send_to_user(new_message, user.id, locale.replies.not_in_cache)
          history.delete_message_group(new_message)
          return
        end
      end

      # TODO: Add R9K write hook

      user.set_active
      database.update_user(user)
      
      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      relay.send_text(
        new_message,
        user,
        receivers,
        reply_msids,
        text,
        entities,
      )
    end


    # Same as overriden method, but returns nil if message is a command
    private def get_message_and_user(update : Tourmaline::Context, database : Database, relay : Relay, locale : Locale) : Tuple(Tourmaline::Message?, User?)
      unless (message = update.message) && (info = message.from)
        return nil, nil
      end

      if entity = message.entities[0]?
        return nil, nil if entity.type == "bot_command"
      end

      if text = message.text
        return nil, nil if text.starts_with?(/^[+-]1/)
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
  end
end
