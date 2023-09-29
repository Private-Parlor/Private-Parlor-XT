require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Animation, config: "relay_animation")]
  class AnimationHandler < UpdateHandler
    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authorized?(user, message, :Animation, services)

      return if spamming?(user, message, services)

      return unless animation = message.animation

      caption, entities = get_caption_and_entities(message, user, services)
      return if message.caption && caption.empty?

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return unless r9k_checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_animation(
        new_message,
        user,
        receivers,
        reply_msids,
        animation.file_id,
        caption,
        entities,
        services.config.allow_spoilers ? message.has_media_spoiler? : false,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_animation?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
