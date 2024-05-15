require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_debug", "toggledebug"], config: "enable_toggle_debug")]
  # A command used to enable or disable debug mode, which relays a copy of a sent message to the sender if it is enabled.
  class ToggleDebugCommand < CommandHandler
    # Relays a copy of a sent message back to the sender if debug mode is enabled; relays messages normally if debug mode is disabled
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
