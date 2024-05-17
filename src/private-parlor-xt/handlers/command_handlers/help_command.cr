require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "help", config: "enable_help")]
  # A command used to view the commands that one can use
  class HelpCommand < CommandHandler
    # Returns a message containing commands that the sender of the *message* can use
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      update_user_activity(user, services)

      services.relay.send_to_user(
        ReplyParameters.new(message.message_id),
        user.id,
        Format.help(
          user,
          services.access.ranks,
          services,
          services.command_descriptions,
          services.replies,
        )
      )
    end
  end
end
