require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "uncooldown", config: "enable_uncooldown")]
  class UncooldownCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Uncooldown, services)

      unless arg = Format.get_arg(message.text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      unless uncooldown_user = services.database.get_user_by_arg(arg)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_user_found)
      end

      unless cooldown_until = uncooldown_user.cooldown_until
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cooldown)
      end

      update_user_activity(user, services)

      uncooldown_user.remove_cooldown(true)
      uncooldown_user.remove_warning(1, services.config.warn_lifespan.hours)
      services.database.update_user(uncooldown_user)

      log = Format.substitute_message(services.logs.removed_cooldown, {
        "id"             => user.id.to_s,
        "name"           => user.get_formatted_name,
        "oid"            => uncooldown_user.get_obfuscated_id,
        "cooldown_until" => cooldown_until.to_s,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
