require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Video, config: "relay_video")]
  class VideoHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Video, services)

      return if spamming?(user, message, services)

      return unless video = message.video

      return unless check_text(message.caption, user, message, services)

      # TODO: Add R9K check hook

      caption, entities = format_text(message.caption, message.caption_entities, message.preformatted?, services)

      # TODO: Add pseudonymous hook

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      # TODO: Add R9K write hook

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_video(
        new_message,
        user,
        receivers,
        reply_msids,
        video.file_id,
        caption,
        entities,
        services.config.allow_spoilers ? message.has_media_spoiler? : false,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_video?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      false
    end
  end
end
