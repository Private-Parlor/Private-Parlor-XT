require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Contact, config: "relay_contact")]
  # A handler for contact message updates
  class ContactHandler < UpdateHandler
    # Checks if the contact message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Contact, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless contact = message.contact

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      record_message_statistics(Statistics::Messages::Contacts, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_contact(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
        ),
        contact,
      )
    end

    # Checks if the user is spamming contacts
    #
    # Returns `true` if the user is spamming contacts, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_contact?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a contacts when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for contacts is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_contact >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_contact
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_contact.to_s,
            "type"   => "contact",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a contacts message
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_contact >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_contact)

      user
    end
  end
end
