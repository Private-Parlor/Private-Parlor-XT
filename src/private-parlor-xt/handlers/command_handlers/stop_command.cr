require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "stop", config: "enable_stop")]
  class StopCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      return unless (message = context.message) && (info = message.from)

      unless (user = services.database.get_user(info.id.to_i64)) && !user.left?
        return services.relay.send_to_user(nil, info.id.to_i64, services.locale.replies.not_in_chat)
      end

      user.update_names(info.username, info.full_name)
      user.set_active
      user.set_left
      services.database.update_user(user)

      services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.left)

      log = Format.substitute_message(services.locale.logs.left, {
        "id"   => user.id.to_s,
        "name" => user.get_formatted_name,
      })

      services.relay.log_output(log)
    end
  end
end
