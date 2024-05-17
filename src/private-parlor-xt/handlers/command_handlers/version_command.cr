require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "version", config: "enable_version")]
  # A handler for getting the version of this bot and its source code
  class VersionCommand < CommandHandler
    # Returns a message containing this bots's version number and a link to the soure code if the user exists and is not blacklisted
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, version)
    end

    # Returns a message containing the program version and a link to its Git repo.
    #
    # Feel free to edit this if you fork the code.
    def version : String
      "Private Parlor XT v#{Format.escape_mdv2(VERSION)} \\~ [\\[Source\\]](https://github.com/Private-Parlor/Private-Parlor-XT)"
    end
  end
end
