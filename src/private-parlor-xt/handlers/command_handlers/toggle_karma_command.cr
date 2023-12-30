require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_karma", "togglekarma"], config: "enable_toggle_karma")]
  class ToggleKarmaCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      message, user = get_message_and_user(message, services)
      return unless message && user

      user.toggle_karma

      update_user_activity(user, services)

      response = Format.substitute_reply(services.replies.toggle_karma, {
        "toggle" => user.hide_karma ? services.locale.toggle[0] : services.locale.toggle[1],
      })

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
