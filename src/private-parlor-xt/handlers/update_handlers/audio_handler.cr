require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Audio, config: "relay_audio")]
  # A handler for audio message updates
  class AudioHandler < UpdateHandler
    # Checks if the audio message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Audio, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless audio = message.audio

      caption, entities = Format.text_and_entities(message, user, services)
      return unless caption

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::Messages::Audio, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_audio(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: audio.file_id,
          text: caption,
          entities: entities,
        )
      )
    end

    # Checks if the user is spamming audio messages
    #
    # Returns `true` if the user is spamming audio messages, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_audio?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a audio message when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for audio messages is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_audio >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_audio
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_audio.to_s,
            "type"   => "audio",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a audio message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_audio >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_audio)

      user
    end
  end
end
