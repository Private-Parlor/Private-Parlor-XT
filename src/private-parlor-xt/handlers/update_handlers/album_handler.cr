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

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless album = message.media_group_id

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_messages

      return unless Robot9000.checks(user, message, services)

      user = spend_karma(user, message, services)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      return unless input = get_album_input(message, caption, entities, services.config.allow_spoilers)

      record_message_statistics(Statistics::MessageCounts::Albums, services)

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

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
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
