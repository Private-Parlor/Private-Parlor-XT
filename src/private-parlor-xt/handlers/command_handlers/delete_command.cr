require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "delete", config: "enable_delete")]
  # A command used to delete a message and give its sender a cooldown and warning
  class DeleteCommand < CommandHandler
    # Deletes the reply of the given *message* for everybody and gives a cooldown and warning to the user who sent it, if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Delete, services)

      return unless reply = reply_message(user, message, services)

      return unless reply_user = reply_user(user, reply, services)

      update_user_activity(user, services)

      original_message = delete_messages(
        reply.message_id.to_i64,
        reply_user.id,
        reply_user.debug_enabled,
        services,
      )

      duration = reply_user.cooldown(services.config.cooldown_base)
      reply_user.warn(services.config.warn_lifespan)
      reply_user.decrement_karma(services.config.warn_deduction)
      services.database.update_user(reply_user)

      reason = Format.get_arg(message.text)

      cooldown_until = Format.time_span(duration, services.locale)

      response = Format.substitute_reply(services.replies.message_deleted, {
        "reason"   => Format.reason(reason, services.replies),
        "duration" => cooldown_until,
      })

      log = Format.substitute_message(services.logs.message_deleted, {
        "id"       => user.id.to_s,
        "name"     => user.formatted_name,
        "msid"     => original_message.to_s,
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
