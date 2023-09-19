require "../../handlers.cr"
require "../../services.cr"
require "tourmaline"

module PrivateParlorXT
  @[Hears(text: /^\+1/, config: "enable_upvote")]
  class UpvoteHandler < HearsHandler

    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(ctx, services)
      return unless message && user

      return unless is_authorized?(user, message, :Upvote, services)

      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      return if is_spamming?(user, message, services)

      update_user_activity(user, services)

      return unless upvote_message(user, reply_user, message, reply, services)

      send_replies(user, reply_user, message, reply, services)
    end

    def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, services)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    def is_spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_upvote?(user.id, services.config.upvote_limit_interval)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      return false
    end

    # Adds user's upvote to message history and update reply_user's karma
    # Returns false if user has already upvoted the message or user attempted
    # to give himself karma
    def upvote_message(user : User, reply_user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services) : Bool
      if user.id == reply_user.id
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.upvoted_own_message)
        return false
      end
      if !services.history.add_rating(reply.message_id.to_i64, user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.already_voted)
        return false
      end

      reply_user.increment_karma
      services.database.update_user(reply_user)

      true
    end

    def send_replies(user : User, reply_user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services) : Nil
      services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.gave_upvote)

      unless reply_user.hide_karma
        services.relay.send_to_user(
          services.history.get_receiver_message(reply.message_id.to_i64, reply_user.id),
          reply_user.id,
          services.locale.replies.got_upvote
        )
      end
    end
  end
end
