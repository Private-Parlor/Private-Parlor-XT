require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["motd", "rules"], config: "enable_motd")]
  # A command used to view or set the bot's MOTD
  class MotdCommand < CommandHandler
    # Returns a message containing the MOTD/rules that were set for this bot,
    # or sets the MOTD/rules to a new value if the sender of the *message* is authorized to do so
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      if arg = Format.get_arg(message.text)
        return unless authorized?(user, message, :MotdSet, services)

        services.database.set_motd(arg)

        log = Format.substitute_message(services.logs.motd_set, {
          "id"   => user.id.to_s,
          "name" => user.formatted_name,
          "text" => arg,
        })

        services.relay.log_output(log)

        response = services.replies.success
      else
        return unless motd = services.database.motd

        response = motd
      end

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
