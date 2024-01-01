require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "stop", config: "enable_stop")]
  class StopCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless info = message.from

      if text = message.text || message.caption
        return unless text.starts_with?('/')
      end

      unless user = services.database.get_user(info.id.to_i64)
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      if user.left?
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      user.update_names(info.username, info.full_name)
      user.set_active
      user.set_left
      services.database.update_user(user)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.left)

      log = Format.substitute_message(services.logs.left, {
        "id"   => user.id.to_s,
        "name" => user.get_formatted_name,
      })

      services.relay.log_output(log)
    end
  end
end
