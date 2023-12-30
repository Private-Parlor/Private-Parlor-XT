require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Text, config: "relay_text")]
  class TextHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      message, user = get_message_and_user(message, services)
      return unless message && user

      return if message.forward_origin

      return unless authorized?(user, message, :Text, services)

      return if spamming?(user, message, services)

      text, entities = Format.get_text_and_entities(message, user, services)
      return unless text

      if reply = message.reply_to_message
        return unless reply_messages = get_reply_receivers(reply, message, user, services)
      end

      return unless Robot9000.text_check(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_text(RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          text: text,
          entities: entities,
        )
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      return false if message.preformatted?

      return true unless text = message.text

      if spam.spammy_text?(user.id, text)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
