require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["unblacklist", "unban"], config: "enable_unblacklist")]
  class UnblacklistCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Unblacklist, services)

      unless arg = Format.get_arg(message.text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      unless unblacklisted_user = services.database.get_user_by_arg(arg)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_user_found)
      end

      unless unblacklisted_user.rank == -10
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      unblacklisted_user.set_rank(services.config.default_rank)
      unblacklisted_user.rejoin

      services.database.update_user(unblacklisted_user)

      log = Format.substitute_message(services.logs.unblacklisted, {
        "id"      => unblacklisted_user.id.to_s,
        "name"    => unblacklisted_user.get_formatted_name,
        "invoker" => user.get_formatted_name,
      })

      services.relay.send_to_user(nil, unblacklisted_user.id, services.replies.unblacklisted)

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
