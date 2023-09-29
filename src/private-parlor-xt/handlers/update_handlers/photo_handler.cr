require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Photo, config: "relay_photo")]
  class PhotoHandler < UpdateHandler
    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Photo, services)

      return if spamming?(user, message, services)

      return unless photo = message.photo.last

      caption, entities = get_caption_and_entities(message, user, services)
      return if message.caption && caption.empty?

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return false unless r9k_checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_photo(
        new_message,
        user,
        receivers,
        reply_msids,
        photo.file_id,
        caption,
        entities,
        services.config.allow_spoilers ? message.has_media_spoiler? : false,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_photo?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
