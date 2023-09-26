require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_debug", "toggledebug"], config: "enable_toggle_debug")]
  class ToggleDebugCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      user.toggle_debug

      update_user_activity(user, services)

      response = Format.substitute_message(services.locale.replies.toggle_debug, {
        "toggle" => user.debug_enabled ? services.locale.toggle[1] : services.locale.toggle[0],
      })

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
