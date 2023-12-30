require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "help", config: "enable_help")]
  class HelpCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services)
      message, user = get_message_and_user(message, services)
      return unless message && user

      update_user_activity(user, services)

      services.relay.send_to_user(
        ReplyParameters.new(message.message_id),
        user.id,
        Format.format_help(
          user,
          services.access.ranks,
          services.command_descriptions,
          services.replies,
        )
      )
    end
  end
end
