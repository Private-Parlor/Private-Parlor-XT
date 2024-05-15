require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["toggle_karma", "togglekarma"], config: "enable_toggle_karma")]
  # A command used to disable or enable karma notifications for a user
  class ToggleKarmaCommand < CommandHandler
    # Hides karma notifications for user or enabled them, depending on the user's hide_karma value
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      user.toggle_karma

      update_user_activity(user, services)

      response = Format.substitute_reply(services.replies.toggle_karma, {
        "toggle" => user.hide_karma ? services.locale.toggle[0] : services.locale.toggle[1],
      })

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
