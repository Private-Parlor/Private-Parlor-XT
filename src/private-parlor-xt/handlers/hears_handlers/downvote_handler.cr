require "../../handlers.cr"
require "../../services.cr"
require "tourmaline"

module PrivateParlorXT
  @[Hears(text: /^\-1/, config: "enable_downvote")]
  class DownvoteHandler < HearsHandler

    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(ctx, services)
      return unless message && user

      unless services.access.authorized?(user.rank, :Downvote)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.fail)
      end
      unless reply = message.reply_to_message
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.no_reply)
      end
      unless reply_user = services.database.get_user(services.history.get_sender(reply.message_id.to_i64))
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.not_in_cache)
      end
      if (spam = services.spam) && spam.spammy_downvote?(user.id, services.config.downvote_limit_interval)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
      end

      user.set_active
      services.database.update_user(user)

      if user.id == reply_user.id
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.downvoted_own_message)
      end
      if !services.history.add_rating(reply.message_id.to_i64, user.id)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.already_voted)
      end

      reply_user.decrement_karma
      services.database.update_user(reply_user)

      services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.gave_downvote)

      unless reply_user.hide_karma
        services.relay.send_to_user(
          services.history.get_receiver_message(reply.message_id.to_i64, reply_user.id),
          reply_user.id,
          services.locale.replies.got_downvote
        )
      end
    end

    private def get_message_and_user(ctx : Tourmaline::Context, services : Services) : Tuple(Tourmaline::Message?, User?)
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
  end
end
