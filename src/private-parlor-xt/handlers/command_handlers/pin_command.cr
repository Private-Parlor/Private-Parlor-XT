require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "pin", config: "enable_pin")]
  # A command for pinning messages to the chat
  class PinCommand < CommandHandler
    # Pins the message that *message* replies to if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Pin, services)

      return unless reply = reply_message(user, message, services)

      unless services.history.sender(reply.message_id.to_i64)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cache)
      end

      update_user_activity(user, services)

      services.history.receivers(reply.message_id.to_i64).each do |receiver, receiver_message|
        services.relay.pin_message(receiver, receiver_message)
      end

      log = Format.substitute_message(services.logs.pinned, {
        "id"   => user.id.to_s,
        "name" => user.formatted_name,
        "msid" => reply.message_id.to_s,
      })

      services.relay.log_output(log)

      # On success, a Telegram system message
      # will be displayed saying that the bot has pinned the message
    end
  end
end
