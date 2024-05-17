require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "reveal", config: "enable_reveal")]
  # A command used to privately reveal one's username to another user.
  class RevealCommand < CommandHandler
    # Privately sends the *message* sender's username signature to the sender of the message this *message* replies to, if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Reveal, services)

      if (chat = services.relay.get_chat(user.id)) && chat.has_private_forwards?
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.private_sign)
      end

      return unless reply = reply_message(user, message, services)

      return unless reply_user = reply_user(user, reply, services)

      if reply_user.id == user.id
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      if (spam = services.spam) && spam.spammy_sign?(user.id, services.config.sign_limit_interval)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.sign_spam)
      end

      update_user_activity(user, services)

      receiver_message = services.history.receiver_message(reply.message_id.to_i64, reply_user.id)

      response = user_reveal(user.id, user.formatted_name, services.replies)

      if receiver_message
        receiver_message = ReplyParameters.new(receiver_message)
      end

      services.relay.send_to_user(receiver_message, reply_user.id, response)

      log = Format.substitute_message(services.logs.revealed, {
        "sender_id"   => user.id.to_s,
        "sender"      => user.formatted_name,
        "receiver_id" => reply_user.id.to_s,
        "receiver"    => reply_user.formatted_name,
        "msid"        => reply.message_id.to_s,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end

    # Returns a link to a given user's account, for reveal messages
    def user_reveal(id : UserID, name : String, replies : Replies) : String
      replies.username_reveal.gsub("{username}", "[#{Format.escape_mdv2(name)}](tg://user?id=#{id})")
    end
  end
end
