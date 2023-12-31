require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "warn", config: "enable_warn")]
  class WarnCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Warn, services)

      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      if services.history.get_warning(reply.message_id.to_i64)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.already_warned)
      end

      update_user_activity(user, services)

      services.history.add_warning(reply.message_id.to_i64)

      duration = reply_user.cooldown(services.config.cooldown_base)
      reply_user.warn(services.config.warn_lifespan)
      reply_user.decrement_karma(services.config.warn_deduction)
      services.database.update_user(reply_user)

      original_message = services.history.get_origin_message(reply.message_id.to_i64)

      reason = Format.get_arg(message.text)

      cooldown_until = Format.format_time_span(duration, services.locale)

      response = Format.substitute_reply(services.replies.cooldown_given, {
        "reason"   => Format.format_reason_reply(reason, services.replies),
        "duration" => cooldown_until,
      })

      log = Format.substitute_message(services.logs.warned, {
        "id"       => user.id.to_s,
        "name"     => user.get_formatted_name,
        "oid"      => reply_user.get_obfuscated_id,
        "duration" => cooldown_until,
        "reason"   => Format.format_reason_log(reason, services.logs),
      })

      if original_message
        original_message = ReplyParameters.new(original_message)
      end

      services.relay.send_to_user(original_message, reply_user.id, response)

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end
  end
end
