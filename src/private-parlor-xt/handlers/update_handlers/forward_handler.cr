require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :ForwardedMessage, config: "relay_forwarded_message")]
  class ForwardHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Forward, services)

      return if deanonymous_poll(user, message, services)

      return if spamming?(user, message, services)

      return unless r9k_forward_checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_forward(
        new_message,
        user,
        receivers,
        message.message_id.to_i64
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_forward?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end

    def deanonymous_poll(user : User, message : Tourmaline::Message, services : Services) : Bool
      if (poll = message.poll) && (!poll.is_anonymous?)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.deanon_poll)
        return true
      end

      false
    end
  end
end
