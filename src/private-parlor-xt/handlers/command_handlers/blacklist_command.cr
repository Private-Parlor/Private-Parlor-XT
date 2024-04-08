require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["blacklist", "ban"], config: "enable_blacklist")]
  class BlacklistCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Blacklist, services)

      if reply = message.reply_to_message
        arg = Format.get_arg(message.text)
        blacklist_from_reply(arg, user, message.message_id.to_i64, reply, services)
      else
        unless args = Format.get_args(message.text, count: 2)
          return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
        end

        blacklist_from_args(args, user, message.message_id.to_i64, services)
      end
    end

    def blacklist_from_reply(reason : String?, user : User, message : MessageID, reply : Tourmaline::Message, services : Services)
      return unless reply_user = get_reply_user(user, reply, services)

      return unless blacklist_user(reply_user, user, message, reason, services)

      original_message = delete_messages(
        reply.message_id.to_i64,
        reply_user.id,
        reply_user.debug_enabled,
        true,
        services,
      )

      if original_message
        original_message = ReplyParameters.new(original_message)
      end

      send_messages(reason, reply_user, user, original_message, message, services)
    end

    def blacklist_from_args(args : Array(String), user : User, message : MessageID, services : Services)
      unless blacklisted_user = services.database.get_user_by_arg(args[0])
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.no_user_found)
      end

      return unless blacklist_user(blacklisted_user, user, message, args[1], services)

      send_messages(args[1], blacklisted_user, user, nil, message, services)
    end

    def blacklist_user(blacklisted_user : User, invoker : User, message : MessageID, reason : String?, services : Services) : Bool?
      unless blacklisted_user.rank < invoker.rank
        return services.relay.send_to_user(ReplyParameters.new(message), invoker.id, services.replies.fail)
      end

      update_user_activity(invoker, services)

      blacklisted_user.blacklist(reason)
      services.database.update_user(blacklisted_user)

      services.relay.reject_blacklisted_messages(blacklisted_user.id)

      return true
    end

    def send_messages(reason : String?, blacklisted_user : User, invoker : User, deleted_message : ReplyParameters?, invoker_message : MessageID, services : Services) : Nil
      response = Format.substitute_reply(services.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
        "reason"  => Format.format_reason_reply(reason, services.replies),
      })

      log = Format.substitute_message(services.logs.blacklisted, {
        "id"      => blacklisted_user.id.to_s,
        "name"    => blacklisted_user.get_formatted_name,
        "invoker" => invoker.get_formatted_name,
        "reason"  => Format.format_reason_log(reason, services.logs),
      })

      services.relay.send_to_user(deleted_message, blacklisted_user.id, response)

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(invoker_message), invoker.id, services.replies.success)
    end
  end
end
