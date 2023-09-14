require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[Hears(text: /^\+1/, config: "enable_upvote")]
  class UpvoteHandler < HearsHandler
    @upvote_limit_interval : Int32 = 0

    def initialize(config : Config)
      @upvote_limit_interval = config.upvote_limit_interval
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Upvote)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.fail)
      end
      unless reply = message.reply_to_message
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.no_reply)
      end
      unless reply_user = database.get_user(history.get_sender(reply.message_id.to_i64))
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.not_in_cache)
      end
      if spam && spam.spammy_upvote?(user.id, @upvote_limit_interval)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      user.set_active
      database.update_user(user)

      if user.id == reply_user.id
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.upvoted_own_message)
      end
      if !history.add_rating(reply.message_id.to_i64, user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.already_voted)
      end

      reply_user.increment_karma
      database.update_user(reply_user)

      relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.gave_upvote)

      unless reply_user.hide_karma
        relay.send_to_user(
          history.get_receiver_message(reply.message_id.to_i64, reply_user.id),
          reply_user.id,
          locale.replies.got_upvote
        )
      end
    end

    private def get_message_and_user(ctx : Tourmaline::Context, database : Database, relay : Relay, locale : Locale) : Tuple(Tourmaline::Message?, User?)
      unless (message = ctx.message) && (info = message.from)
        return nil, nil
      end

      unless user = database.get_user(info.id.to_i64)
        relay.send_to_user(nil, info.id.to_i64, locale.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, relay, locale)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end
  end
end
