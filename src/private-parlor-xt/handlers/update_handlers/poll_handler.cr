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

      user.set_active
      database.update_user(user)

      cached_message = history.new_message(user.id, message.message_id.to_i64)
      poll_copy = relay.send_poll_copy(cached_message, user, poll)
      history.add_to_history(cached_message, poll_copy.message_id.to_i64, user.id)

      # Disable debug mode so the user does not get a second copy of the poll
      if user.debug_enabled
        user.toggle_debug
      end

      if reply = message.reply_to_message
        reply = reply.message_id.to_i64
      else
        reply = nil
      end

      relay.send_poll(
        reply,
        user,
        cached_message,
        poll_copy.message_id.to_i64,
        locale,
        history,
        database
      )
    end
  end
end