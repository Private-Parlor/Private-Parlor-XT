require "../../hears_handler.cr"
require "../../services.cr"
require "tourmaline"

module PrivateParlorXT
  @[Hears(text: /^\-1/, config: "enable_downvote")]
  class DownvoteHandler < HearsHandler
    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Downvote, services)

      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      return if spamming?(user, message, services)

      update_user_activity(user, services)

      return unless downvote_message(user, reply_user, message, reply, services)

      send_replies(user, reply_user, message, reply, services)
    end

    def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, services)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    def authorized?(user : User, message : Tourmaline::Message, authority : CommandPermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, authority)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.fail)
        return false
      end

      true
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_downvote?(user.id, services.config.downvote_limit_interval)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end

    # Adds user's dowvote to message history and update reply_user's karma
    # Returns false if user has already downvoted the message or user attempted
    # to remove his own karma
    def downvote_message(user : User, reply_user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services) : Bool
      if user.id == reply_user.id
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.downvoted_own_message)
        return false
      end
      if !services.history.add_rating(reply.message_id.to_i64, user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.already_voted)
        return false
      end

      reply_user.decrement_karma
      services.database.update_user(reply_user)

      true
    end

    def send_replies(user : User, reply_user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services) : Nil
      services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.gave_downvote)

      unless reply_user.hide_karma
        services.relay.send_to_user(
          services.history.get_receiver_message(reply.message_id.to_i64, reply_user.id),
          reply_user.id,
          services.replies.got_downvote
        )
      end
    end
  end
end
