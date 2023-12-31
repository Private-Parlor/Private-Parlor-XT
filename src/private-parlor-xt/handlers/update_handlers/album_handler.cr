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

    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :MediaGroup, services)

      return if spamming?(user, message, services)

      return unless album = message.media_group_id

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_exists?(message, reply_messages, user, services)

      return unless Robot9000.checks(user, message, services)

      return unless user = spend_karma(user, message, services)

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
        reply_messages,
        services
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      return false if (album = message.media_group_id) && @albums[album]?

      if spam.spammy_album?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def spend_karma(user : User, message : Tourmaline::Message, services : Services) : User?
      return user unless karma = services.karma

      return user if user.rank >= karma.cutoff_rank

      return user if (album = message.media_group_id) && @albums[album]?

      unless user.karma >= karma.karma_media_group
        # TODO: Add locale entry
        return
      end

      if karma.karma_media_group >= 0
        user.decrement_karma(karma.karma_media_group)
      end

      user
    end
  end
end
