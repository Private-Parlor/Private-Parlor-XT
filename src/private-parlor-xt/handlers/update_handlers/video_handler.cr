require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Video, config: "relay_video")]
  # A handler for video message updates
  class VideoHandler < UpdateHandler
    # Checks if the video message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Video, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless video = message.video

      caption, entities = Format.text_and_entities(message, user, services)
      return unless caption

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::Messages::Videos, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_video(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: video.file_id,
          text: caption,
          entities: entities,
          spoiler: services.config.allow_spoilers ? message.has_media_spoiler? : false,
          effect: services.config.allow_effects ? message.effect_id : nil,
          caption_above_media: message.show_caption_above_media?,
        )
      )
    end

    # Checks if the user is spamming video messages
    #
    # Returns `true` if the user is spamming video messages, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_video?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a video message when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for video messages is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_video >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_video
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_video.to_s,
            "type"   => "video",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a video message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_video >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_video)

      user
    end
  end
end
