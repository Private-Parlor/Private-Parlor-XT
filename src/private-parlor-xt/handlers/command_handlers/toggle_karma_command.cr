require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_karma", "togglekarma"], config: "enable_toggle_karma")]
  class ToggleKarmaCommand < CommandHandler
    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      user.toggle_karma

      update_user_activity(user, services)

      response = Format.substitute_reply(services.replies.toggle_karma, {
        "toggle" => user.hide_karma ? services.locale.toggle[0] : services.locale.toggle[1],
      })

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
