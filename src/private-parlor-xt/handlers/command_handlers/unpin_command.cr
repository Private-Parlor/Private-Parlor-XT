require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "unpin", config: "enable_unpin")]
  class UnpinCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Unpin, services)

      if reply = message.reply_to_message
        unless services.history.get_sender(reply.message_id.to_i64)
          return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cache)
        end

        services.history.get_all_receivers(reply.message_id.to_i64).each do |receiver, receiver_message|
          services.relay.unpin_message(receiver, receiver_message)
        end

        log = Format.substitute_message(services.logs.unpinned, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "msid" => reply.message_id.to_s,
        })
      else
        services.database.get_active_users.each do |receiver|
          services.relay.unpin_message(receiver)
        end

        log = Format.substitute_message(services.logs.unpinned_recent, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
        })
      end

      update_user_activity(user, services)

      services.relay.log_output(log)

      services.relay.delay_send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
