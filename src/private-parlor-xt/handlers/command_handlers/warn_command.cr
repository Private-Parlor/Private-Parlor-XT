require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "warn", config: "enable_warn")]
  # A command used to give a user a warning and a cooldown without deleting the message
  class WarnCommand < CommandHandler
    # Warns the user who sent a message the given *message* replies to if the *message* meets requirements
    # 
    # Warning a message will give the sender a warning and a cooldown, but will not delete the message
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Warn, services)

      return unless reply = reply_message(user, message, services)

      return unless reply_user = reply_user(user, reply, services)

      if services.history.warned?(reply.message_id.to_i64)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.already_warned)
      end

      update_user_activity(user, services)

      services.history.add_warning(reply.message_id.to_i64)

      duration = reply_user.cooldown(services.config.cooldown_base)
      reply_user.warn(services.config.warn_lifespan)
      reply_user.decrement_karma(services.config.warn_deduction)
      services.database.update_user(reply_user)

      original_message = services.history.origin_message(reply.message_id.to_i64)

      reason = Format.get_arg(message.text)

      cooldown_until = Format.time_span(duration, services.locale)

      response = Format.substitute_reply(services.replies.cooldown_given, {
        "reason"   => Format.reason(reason, services.replies),
        "duration" => cooldown_until,
      })

      log = Format.substitute_message(services.logs.warned, {
        "id"       => user.id.to_s,
        "name"     => user.formatted_name,
        "oid"      => reply_user.obfuscated_id,
        "duration" => cooldown_until,
        "reason"   => Format.reason_log(reason, services.logs),
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
