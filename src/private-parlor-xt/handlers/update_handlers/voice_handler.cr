require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Voice, config: "relay_voice")]
  class VoiceHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      message, user = get_message_and_user(message, services)
      return unless message && user

      return if message.forward_origin

      return unless authorized?(user, message, :Voice, services)

      return if spamming?(user, message, services)

      return unless voice = message.voice

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      if reply = message.reply_to_message
        return unless reply_messages = get_reply_receivers(reply, message, user, services)
      end

      return unless Robot9000.checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_voice(RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: voice.file_id,
          text: caption,
          entities: entities,
        )
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_voice?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
