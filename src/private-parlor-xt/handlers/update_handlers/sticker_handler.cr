require "../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Sticker, config: "relay_sticker")]
  # A handler for sticker updates
  class StickerHandler < UpdateHandler
    # Checks if the sticker meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Sticker, services)

      return unless sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless sticker = message.sticker

      reply_messages = reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::Messages::Stickers, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = message_receivers(user, services)

      services.relay.send_sticker(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: sticker.file_id,
        )
      )
    end

    # Checks if the user is spamming stickers
    #
    # Returns `true` if the user is spamming stickers, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_sticker?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send a sticker when `KarmaHandler` is enabled
    #
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for stickers is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    #
    # Returns `nil` if the user does not have sufficient karma
    def sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_sticker >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_sticker
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_sticker.to_s,
            "type"   => "sticker",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and
    # *user* has sufficient karma for a sticker
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_sticker >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_sticker)

      user
    end
  end
end
