require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Animation, config: "relay_animation")]
  # A handler for animation message updates
  class AnimationHandler < UpdateHandler
    # Checks if the animation message meets requirements and relays it
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Animation, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless animation = message.animation

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_messages

      return unless unique?(user, message, services)

      record_message_statistics(Statistics::MessageCounts::Animations, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_animation(
        RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
          replies: reply_messages,
          media: animation.file_id,
          text: caption,
          entities: entities,
          spoiler: services.config.allow_spoilers ? message.has_media_spoiler? : false,
        )
      )
    end

    # Checks if the user is spamming animations
    # 
    # Returns `true` if the user is spamming animations, `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_animation?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Checks if the user has sufficient karma to send an animation when `KarmaHandler` is enabled
    # 
    # Returns `true` if:
    #   - `KarmaHandler` is not enabled
    #   - The price for animations is less than 0
    #   - The *user's* `Rank` is equal to or greater than the cutoff `Rank`
    #   - User has sufficient karma
    # 
    # Returns `nil` if the user does not have sufficient karma
    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_animation >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_animation
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_animation.to_s,
            "type"   => "animation",
          })
        )
      end

      true
    end

    # Returns the `User` with decremented karma when `KarmaHandler` is enabled and 
    # *user* has sufficient karma for an animation
    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_animation >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_animation)

      user
    end
  end
end
