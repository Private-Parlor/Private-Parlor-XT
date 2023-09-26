require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["blacklist", "ban"], config: "enable_blacklist")]
  class BlacklistCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless is_authorized?(user, message, :Blacklist, services)
 
      return unless reply = get_reply_message(user, message, services)

      return unless reply_user = get_reply_user(user, reply, services)

      unless reply_user.rank < user.rank
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.fail)
      end

      update_user_activity(user, services)

      reason = Format.get_arg(message.text)

      reply_user.blacklist(reason)
      services.database.update_user(reply_user)

      services.relay.reject_blacklisted_messages(reply_user.id)

      original_message = delete_messages(
        reply.message_id.to_i64, 
        reply_user.id,
        reply_user.debug_enabled,
        true,
        services,
      )

      response = Format.substitute_message(services.locale.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.locale),
        "reason" => Format.format_reason_reply(reason, services.locale),
      })

      log = Format.substitute_message(services.locale.logs.blacklisted, {
        "id"     => reply_user.id.to_s,
        "name"   => reply_user.get_formatted_name,
        "invoker" => user.get_formatted_name,
        "reason" => Format.format_reason_log(reason, services.locale),
      })

      services.relay.send_to_user(original_message, reply_user.id, response)

      services.relay.log_output(log)

      services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.success)
    end
  end
end