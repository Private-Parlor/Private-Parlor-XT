require "../../update_handler.cr"
require "../../constants.cr"
require "../../album_helpers.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  @[On(update: :MediaGroup, config: "relay_media_group")]
  # A handler for album message updates
  class AlbumHandler < UpdateHandler
    include AlbumHelpers

    # A hash of `String`, media group IDs, to `Album`, representing forwarded albums
    property albums : Hash(String, Album) = {} of String => Album

    # Checks if the album message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :MediaGroup, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless album = message.media_group_id

      caption, entities = Format.text_and_entities(message, user, services)
      return unless caption

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      return unless input = album_input(message, caption, entities, services.config.allow_spoilers)

      record_message_statistics(Statistics::Messages::Albums, services)

      user = spend_karma(user, message, services)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

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

    # Checks if the user is spamming albums
    #
    # Returns `true` if the user is spamming albums, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      return false if (album = message.media_group_id) && @albums[album]?

      if spam.spammy_album?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send an album when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for albums is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_media_group >= 0

      return true if user.rank >= karma.cutoff_rank

      return true if (album = message.media_group_id) && @albums[album]?

      unless user.karma >= karma.karma_media_group
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_media_group.to_s,
            "type"   => "album",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for an album
    def spend_karma(user : User, message : Tourmaline::Message, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_media_group >= 0

      return user if user.rank >= karma.cutoff_rank

      return user if (album = message.media_group_id) && @albums[album]?

      user.decrement_karma(karma.karma_media_group)

      user
    end
  end
end
