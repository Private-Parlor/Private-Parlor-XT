require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :ForwardedMessage, config: "relay_forwarded_message")]
  # A handler for forwarded message updates
  class ForwardHandler < UpdateHandler
    # Checks if the forwarded message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Forward, services)

      return if deanonymous_poll?(user, message, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::Messages::Forwards, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_forward(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
        ),
        message.message_id.to_i64
      )
    end

    # Checks if the user is spamming forwarded messages
    #
    # Returns `true` if the user is spamming forwarded messages, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_forward?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Returns `true` if the forwarded poll does not have anonymous voting
    #
    # Returns `false` otherwise
    def deanonymous_poll?(user : User, message : Tourmaline::Message, services : Services) : Bool
      if (poll = message.poll) && (!poll.is_anonymous?)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.deanon_poll)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a forwarded message when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for forwarded messages is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_forwarded_message >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_forwarded_message
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_forwarded_message.to_s,
            "type"   => "forward",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a forwarded message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_forwarded_message >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_forwarded_message)

      user
    end
  end
end
