require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "whitelist", config: "enable_whitelist")]
  # A command used to whitelist users through the Telegram bot
  class WhitelistCommand < CommandHandler
    # Whitelists a user, allowing them to join the chat, if the given *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Whitelist, services)

      if services.config.registration_open
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      unless (arg = Format.get_arg(message.text)) && (arg = arg.to_i64?)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      if services.database.get_user(arg)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.already_whitelisted)
      end

      update_user_activity(user, services)

      services.database.add_user(arg, "", "WHITELISTED", services.config.default_rank)

      # Sends a message to the user only if the user has started a
      # conversation with the bot prior to being whitelisted
      services.relay.send_to_user(nil, arg, services.replies.added_to_chat)

      log = Format.substitute_message(services.logs.whitelisted, {
        "id"      => arg.to_s,
        "invoker" => user.formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
