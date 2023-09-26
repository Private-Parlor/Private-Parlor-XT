require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "tripcode", config: "enable_tripcode")]
  class TripcodeCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      if arg = Format.get_arg(message.text)
        unless valid_tripcode?(arg)
          return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.invalid_tripcode_format)
        end

        user.set_tripcode(arg)

        name, tripcode = Format.generate_tripcode(arg, services.config.tripcode_salt)

        response = Format.substitute_message(services.locale.replies.tripcode_set, {
          "name"     => name,
          "tripcode" => tripcode,
        })
      else
        response = Format.substitute_message(services.locale.replies.tripcode_info, {
          "tripcode" => user.tripcode ? user.tripcode : services.locale.replies.tripcode_unset,
        })
      end

      update_user_activity(user, services)

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
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
