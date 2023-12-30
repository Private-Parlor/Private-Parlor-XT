require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Poll, config: "relay_poll")]
  class PollHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      message, user = get_message_and_user(message, services)
      return unless message && user

      return if message.forward_origin

      return unless authorized?(user, message, :Poll, services)

      return if spamming?(user, message, services)

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
  end
end
