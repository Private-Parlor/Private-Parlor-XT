require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "delete", config: "enable_delete")]
  class DeleteCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Delete, services)

      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      update_user_activity(user, services)

      original_message = delete_messages(
        reply.message_id.to_i64,
        reply_user.id,
        reply_user.debug_enabled,
        true,
        services,
      )

      duration = reply_user.cooldown(services.config.cooldown_base)
      reply_user.warn(services.config.warn_lifespan)
      reply_user.decrement_karma(services.config.warn_deduction)
      services.database.update_user(reply_user)

      reason = Format.get_arg(message.text)

      cooldown_until = Format.format_time_span(duration, services.locale)

      response = Format.substitute_reply(services.replies.message_deleted, {
        "reason"   => Format.format_reason_reply(reason, services.replies),
        "duration" => cooldown_until,
      })

      log = Format.substitute_message(services.logs.message_deleted, {
        "id"       => user.id.to_s,
        "name"     => user.get_formatted_name,
        "msid"     => original_message.to_s,
        "oid"      => reply_user.get_obfuscated_id,
        "duration" => cooldown_until,
        "reason"   => Format.format_reason_log(reason, services.logs),
      })

      services.relay.send_to_user(original_message, reply_user.id, response)

      services.relay.log_output(log)

      # TODO: Move this reply to end of queue
      services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.success)
    end
  end
end
