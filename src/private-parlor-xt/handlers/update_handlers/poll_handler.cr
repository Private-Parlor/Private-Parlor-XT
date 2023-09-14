require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Poll, config: "relay_poll")]
  class PollHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Poll)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "poll"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      return if message.forward_date
      return unless poll = message.poll

      if spam && spam.spammy_poll?(user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      cached_message = history.new_message(user.id, message.message_id.to_i64)

      if reply = message.reply_to_message
        reply_msids = history.get_all_receivers(reply.message_id.to_i64)

        if reply_msids.empty?
          relay.send_to_user(cached_message, user.id, locale.replies.not_in_cache)
          history.delete_message_group(cached_message)
          return
        end
      end

      poll_copy = relay.send_poll_copy(cached_message, user, poll)
      history.add_to_history(cached_message, poll_copy.message_id.to_i64, user.id)

      user.set_active
      database.update_user(user)

      receivers = database.get_active_users(user.id)

      relay.send_poll(
        cached_message,
        user,
        receivers,
        poll_copy.message_id.to_i64,
      )
    end
  end
end
