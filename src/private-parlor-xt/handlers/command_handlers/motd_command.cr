require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["motd", "rules"], config: "enable_motd")]
  class MotdCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      if arg = Format.get_arg(message.text)
        return unless authorized?(user, message, :MotdSet, services)

        update_user_activity(user, services)

        services.database.set_motd(arg)

        log = Format.substitute_message(services.locale.logs.motd_set, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "text" => arg,
        })

        services.relay.log_output(log)

        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.success)
      else
        return unless motd = services.database.get_motd

        update_user_activity(user, services)

        services.relay.send_to_user(message.message_id.to_i64, user.id, motd)
      end
    end
  end
end
