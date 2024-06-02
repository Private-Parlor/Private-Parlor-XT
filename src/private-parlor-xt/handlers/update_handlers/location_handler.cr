require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Location, config: "relay_location")]
  # A handler for location message updates
  class LocationHandler < UpdateHandler
    # Checks if the location message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Location, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless location = message.location

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      record_message_statistics(Statistics::Messages::Locations, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_location(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          effect: services.config.allow_effects ? message.effect_id : nil
        ),
        location,
      )
    end

    # Checks if the user is spamming location messages
    #
    # Returns `true` if the user is spamming location messages, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_location?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a location message when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for location messages is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
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

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a location message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_location >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_location)

      user
    end
  end
end
