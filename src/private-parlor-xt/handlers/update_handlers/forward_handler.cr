require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :ForwardedMessage, config: "relay_forwarded_message")]
  class ForwardHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Forward)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "forward"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      if (poll = message.poll) && (!poll.is_anonymous?)
        relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.deanon_poll)
      end

      if spam && spam.spammy_forward?(user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      # TODO: Add R9K check hook
      new_message = history.new_message(user.id, message.message_id.to_i64)
      # TODO: Add R9K write hook

      user.set_active
      database.update_user(user)

      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      relay.send_forward(
        new_message,
        user,
        receivers,
        message.message_id.to_i64
      )
    end
  end
end
