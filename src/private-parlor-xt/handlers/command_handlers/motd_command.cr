require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["motd", "rules"], config: "enable_motd")]
  class MotdCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      return unless text = message.text

      if arg = text.split(2)[1]?
        unless access.authorized?(user.rank, :MotdSet)
          return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.fail)
        end

        user.set_active
        database.update_user(user)

        database.set_motd(arg)

        log = Format.substitute_message(locale.logs.motd_set, locale, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "text" => arg,
        })

        relay.log_output(log)

        relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.success)
      else
        return unless motd = database.get_motd

        user.set_active
        database.update_user(user)

        relay.send_to_user(message.message_id.to_i64, user.id, motd)
      end
    end
  end
end
