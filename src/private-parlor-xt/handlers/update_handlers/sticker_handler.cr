require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Sticker, config: "relay_sticker")]
  class StickerHandler < UpdateHandler
    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authorized?(user, message, :Sticker, services)

      return if spamming?(user, message, services)

      return unless sticker = message.sticker

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return unless r9k_media(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_sticker(
        new_message,
        user,
        receivers,
        reply_msids,
        sticker.file_id,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_sticker?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
