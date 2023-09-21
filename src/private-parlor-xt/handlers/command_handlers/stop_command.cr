require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "stop", config: "enable_stop")]
  class StopCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      return unless (message = ctx.message) && (info = message.from)

      unless (user = database.get_user(info.id.to_i64)) && !user.left?
        return relay.send_to_user(nil, info.id.to_i64, locale.replies.not_in_chat)
      end

      user.update_names(info.username, info.full_name)
      user.set_active
      user.set_left
      database.update_user(user)

      relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.left)

      log = Format.substitute_message(locale.logs.left, {
        "id"   => user.id.to_s,
        "name" => user.get_formatted_name,
      })

      relay.log_output(log)
    end
  end
end
