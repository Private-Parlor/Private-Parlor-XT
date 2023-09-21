require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_karma", "togglekarma"], config: "enable_toggle_karma")]
  class ToggleKarmaCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      user.set_active
      user.toggle_karma
      database.update_user(user)

      response = Format.substitute_message(locale.replies.toggle_karma, {
        "toggle" => user.hide_karma ? locale.toggle[0] : locale.toggle[1],
      })

      relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
