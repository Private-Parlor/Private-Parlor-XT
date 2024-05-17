require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Voice, config: "relay_voice")]
  # A handler for voice message updates
  class VoiceHandler < UpdateHandler
    # Checks if the voice message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Voice, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless voice = message.voice

      caption, entities = Format.text_and_entities(message, user, services)
      return unless caption

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::Messages::Voice, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_voice(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: voice.file_id,
          text: caption,
          entities: entities,
        )
      )
    end

    # Checks if the user is spamming voice messages
    #
    # Returns `true` if the user is spamming voice messages, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_voice?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a voice message when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for voice messages is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_voice >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_voice
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_voice.to_s,
            "type"   => "voice",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a voice message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_voice >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_voice)

      user
    end
  end
end
