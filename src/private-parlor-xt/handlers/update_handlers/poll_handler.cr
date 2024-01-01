require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Poll, config: "relay_poll")]
  class PollHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Poll, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      user = spend_karma(user, services)

      return unless poll = message.poll

      cached_message = services.history.new_message(user.id, message.message_id.to_i64)
      poll_copy = services.relay.send_poll_copy(cached_message, user, poll)
      services.history.add_to_history(cached_message, poll_copy.message_id.to_i64, user.id)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_forward(RelayParameters.new(
        original_message: cached_message,
        sender: user.id,
        receivers: receivers,
      ),
        poll_copy.message_id.to_i64,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_poll?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
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

    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_poll >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_poll)

      user
    end
  end
end
