require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "whitelist", config: "enable_whitelist")]
  class WhitelistCommand < CommandHandler
    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Whitelist, services)

      if services.config.registration_open
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.fail)
      end

      unless (arg = Format.get_arg(message.text)) && (arg = arg.to_i64?)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.missing_args)
      end

      if services.database.get_user(arg)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.already_whitelisted)
      end

      update_user_activity(user, services)

      services.database.add_user(arg, "", "WHITELISTED", services.config.default_rank)

      # Sends a message to the user only if the user has started a
      # conversation with the bot prior to being whitelisted
      services.relay.send_to_user(nil, arg, services.replies.added_to_chat)

      log = Format.substitute_message(services.logs.whitelisted, {
        "id"      => arg.to_s,
        "invoker" => user.get_formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.success)
    end
  end
end
