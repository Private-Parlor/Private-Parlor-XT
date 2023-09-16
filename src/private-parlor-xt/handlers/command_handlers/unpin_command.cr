require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "unpin", config: "enable_unpin")]
  class UnpinCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Unpin)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.fail)
      end

      if reply = message.reply_to_message
        unless history.get_sender(reply.message_id.to_i64)
          return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.not_in_cache)
        end

        history.get_all_receivers(reply.message_id.to_i64).each do |receiver, receiver_message|
          relay.unpin_message(receiver, receiver_message)
        end

        log = Format.substitute_message(locale.logs.unpinned, locale, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "msid" => reply.message_id.to_s,
        })
      else
        database.get_active_users.each do |receiver|
          relay.unpin_latest_pin(receiver)
        end

        log = Format.substitute_message(locale.logs.unpinned_recent, locale, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
        })
      end

      user.set_active
      database.update_user(user)

      relay.log_output(log)

      relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.success)
    end
  end
end
