require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Text, config: "relay_text")]
  class TextHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authorized?(user, message, :Text, services)

      text, entities = get_text_and_entities(message, user, services)
      return if text.empty?

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      # TODO: Add R9K write hook

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_text(
        new_message,
        user,
        receivers,
        reply_msids,
        text,
        entities,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, text : String, services : Services) : Bool
      return false unless spam = services.spam

      return false if message.preformatted?

      if spam.spammy_text?(user.id, text)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end

    def get_text_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      if text = message.text
        if message.preformatted?
          return text, message.entities
        end
      else
        return "", [] of Tourmaline::MessageEntity
      end

      if spamming?(user, message, text, services)
        return "", [] of Tourmaline::MessageEntity
      end

      unless check_text(text, user, message, services)
        return "", [] of Tourmaline::MessageEntity
      end

      # TODO: Add R9K check hook

      text, entities = format_text(text, message.entities, message.preformatted?, services)

      text, entities = prepend_pseudonym(text, entities, user, message, services)

      return text, entities
    end
  end
end
