require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Location, config: "relay_location")]
  class LocationHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Location, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless location = message.location

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_exists?(message, reply_messages, user, services)

      record_message_statistics(Statistics::MessageCounts::Locations, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_location(RelayParameters.new(
        original_message: new_message,
        sender: user.id,
        receivers: receivers,
        replies: reply_messages,
      ),
        location,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_location?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_location >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_location
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_location.to_s,
            "type"   => "location",
          })
        )
      end

      true
    end

    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_location >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_location)

      user
    end
  end
end
