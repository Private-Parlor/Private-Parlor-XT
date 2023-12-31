require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_debug", "toggledebug"], config: "enable_toggle_debug")]
  class ToggleDebugCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      user.toggle_debug

      update_user_activity(user, services)

      response = Format.substitute_reply(services.replies.toggle_debug, {
        "toggle" => user.debug_enabled ? services.locale.toggle[1] : services.locale.toggle[0],
      })

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
