require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "tripcode", config: "enable_tripcode")]
  class TripcodeCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      if arg = Format.get_arg(message.text)
        unless valid_tripcode?(arg)
          return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.invalid_tripcode_format)
        end

        user.set_tripcode(arg)

        name, tripcode = Format.generate_tripcode(arg, services.config.tripcode_salt)

        response = Format.substitute_reply(services.replies.tripcode_set, {
          "name"     => name,
          "tripcode" => tripcode,
        })
      else
        response = Format.substitute_reply(services.replies.tripcode_info, {
          "tripcode" => user.tripcode ? user.tripcode : services.replies.tripcode_unset,
        })
      end

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end

    def valid_tripcode?(arg : String) : Bool
      return false unless pound_index = arg.index('#')

      return false if pound_index == arg.size - 1

      return false if arg.size > 30

      return false if arg.includes?("\n")

      true
    end
  end
end
