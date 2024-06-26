require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Poll, config: "relay_poll")]
  # A handler for poll message updates
  class PollHandler < UpdateHandler
    # Checks if the poll meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Poll, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless poll = message.poll

      user = spend_karma(user, services)

      cached_message = services.history.new_message(user.id, message.message_id.to_i64)
      poll_copy = services.relay.send_poll_copy(
        cached_message,
        user,
        services.config.allow_effects ? message.effect_id : nil,
        poll
      )
      services.history.add_to_history(cached_message, poll_copy.message_id.to_i64, user.id)

      record_message_statistics(Statistics::Messages::Polls, services)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_forward(
        RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
        ),
        poll_copy.message_id.to_i64,
      )
    end

    # Checks if the user is spamming polls
    #
    # Returns `true` if the user is spamming polls, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_poll?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a poll when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for polls is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_poll >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_poll
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_poll.to_s,
            "type"   => "poll",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a poll
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_poll >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_poll)

      user
    end
  end
end
