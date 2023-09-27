require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Audio, config: "relay_audio")]
  class AudioHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Audio, services)

      return if spamming?(user, message, services)

      return unless audio = message.audio

      caption, entities = get_caption_and_entities(message, user, services)
      return if message.caption && caption.empty?

      # TODO: Add pseudonymous hook

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      # TODO: Add R9K write hook

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_audio(
        new_message,
        user,
        receivers,
        reply_msids,
        audio.file_id,
        caption,
        entities,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_audio?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
