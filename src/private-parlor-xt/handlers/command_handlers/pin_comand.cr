require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "pin", config: "enable_pin")]
  class PinCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Pin)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.fail)
      end
      unless reply = message.reply_to_message
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.no_reply)
      end
      unless history.get_sender(reply.message_id.to_i64)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.not_in_cache)
      end

      user.set_active
      database.update_user(user)

      history.get_all_receivers(reply.message_id.to_i64).each do |receiver, receiver_message|
        relay.pin_message(receiver, receiver_message)
      end

      log = Format.substitute_message(locale.logs.pinned, locale, {
        "id"   => user.id.to_s,
        "name" => user.get_formatted_name,
        "msid" => reply.message_id.to_s,
      })
      relay.log_output(log)

      # On success, a Telegram system message
      # will be displayed saying that the bot has pinned the message
    end
  end
end
