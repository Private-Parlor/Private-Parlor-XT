require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Venue, config: "relay_venue")]
  class VenueHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Venue, services)

      return if spamming?(user, message, services)

      return unless venue = message.venue

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_exists?(message, reply_messages, user, services)

      return unless user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_venue(RelayParameters.new(
        original_message: new_message,
        sender: user.id,
        receivers: receivers,
        replies: reply_messages,
      ),
        venue,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_venue?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def spend_karma(user : User, services : Services) : User?
      return user unless karma = services.karma

      return user if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_venue
        # TODO: Add locale entry
        return
      end

      if karma.karma_venue >= 0
        user.decrement_karma(karma.karma_venue)
      end

      user
    end
  end
end
