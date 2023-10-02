require "../../update_handler.cr"
require "../../constants.cr"
require "../../album_helpers.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  @[On(update: :MediaGroup, config: "relay_media_group")]
  class AlbumHandler < UpdateHandler
    include AlbumHelpers

    property albums : Hash(String, Album) = {} of String => Album

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authorized?(user, message, :MediaGroup, services)

      return if spamming?(user, message, services)

      return unless album = message.media_group_id

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return unless Robot9000.checks(user, message, services)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      return unless input = get_album_input(message, caption, entities, services.config.allow_spoilers)

      relay_album(
        @albums,
        album,
        message.message_id.to_i64,
        input,
        user,
        receivers,
        reply_msids,
        services
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      return false if (album = message.media_group_id) && @albums[album]?

      if spam.spammy_album?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
