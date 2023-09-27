require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Voice, config: "relay_voice")]
  class VoiceHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authorized?(user, message, :Voice, services)

      return if spamming?(user, message, services)

      return unless voice = message.voice

      caption, entities = get_caption_and_entities(message, user, services)
      return if message.caption && caption.empty?

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return unless r9k_checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_voice(
        new_message,
        user,
        receivers,
        reply_msids,
        voice.file_id,
        caption,
        entities,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_voice?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
