require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["motd", "rules"], config: "enable_motd")]
  class MotdCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      if arg = Format.get_arg(message.text)
        return unless authorized?(user, message, :MotdSet, services)

        update_user_activity(user, services)

        services.database.set_motd(arg)

        log = Format.substitute_message(services.logs.motd_set, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "text" => arg,
        })

        services.relay.log_output(log)

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
      else
        return unless motd = services.database.get_motd

        update_user_activity(user, services)

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, motd)
      end
    end
  end
end
