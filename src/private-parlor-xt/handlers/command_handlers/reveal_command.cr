require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "reveal", config: "enable_reveal")]
  class RevealCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      message, user = get_message_and_user(message, services)
      return unless message && user

      return unless authorized?(user, message, :Reveal, services)

      if (chat = message.sender_chat) && chat.has_private_forwards?
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.private_sign)
      end

      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      if reply_user.id == user.id
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      if (spam = services.spam) && spam.spammy_sign?(user.id, services.config.sign_limit_interval)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.sign_spam)
      end

      update_user_activity(user, services)

      receiver_message = services.history.get_receiver_message(reply.message_id.to_i64, reply_user.id)

      response = Format.format_user_reveal(user.id, user.get_formatted_name, services.replies)

      if receiver_message
        receiver_message = ReplyParameters.new(receiver_message)
      end

      services.relay.send_to_user(receiver_message, reply_user.id, response)

      log = Format.substitute_message(services.logs.revealed, {
        "sender_id"   => user.id.to_s,
        "sender"      => user.get_formatted_name,
        "receiver_id" => reply_user.id.to_s,
        "receiver"    => reply_user.get_formatted_name,
        "msid"        => reply.message_id.to_s,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
