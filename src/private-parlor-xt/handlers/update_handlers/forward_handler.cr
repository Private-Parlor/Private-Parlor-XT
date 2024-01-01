require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :ForwardedMessage, config: "relay_forwarded_message")]
  class ForwardHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Forward, services)

      return if deanonymous_poll(user, message, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless Robot9000.forward_checks(user, message, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_forward(RelayParameters.new(
        original_message: new_message,
        sender: user.id,
        receivers: receivers,
      ),
        message.message_id.to_i64
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_forward?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def deanonymous_poll(user : User, message : Tourmaline::Message, services : Services) : Bool
      if (poll = message.poll) && (!poll.is_anonymous?)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.deanon_poll)
        return true
      end

      false
    end

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
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

    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_forwarded_message >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_forwarded_message)

      user
    end
  end
end
