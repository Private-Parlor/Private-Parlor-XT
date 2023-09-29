require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "start", config: "enable_start")]
  class StartCommand < CommandHandler
    def do(context : Tourmaline::Context, services : Services)
      return unless (message = context.message) && (info = message.from)

      if user = services.database.get_user(info.id.to_i64)
        existing_user(user, info.username, info.full_name, message.message_id.to_i64, services)
      else
        new_user(info.id.to_i64, info.username, info.full_name, message.message_id.to_i64, services)
      end
    end

    def existing_user(user : User, username : String?, fullname : String, message_id : MessageID, services : Services)
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
        })

        services.relay.send_to_user(nil, user.id, response)
      elsif user.left?
        user.rejoin
        user.update_names(username, fullname)
        user.set_active
        services.database.update_user(user)

        services.relay.send_to_user(message_id, user.id, services.replies.rejoined)

        log = Format.substitute_message(services.logs.rejoined, {"id" => user.id.to_s, "name" => user.get_formatted_name})

        services.relay.log_output(log)
      else
        user.update_names(username, fullname)
        user.set_active

        services.database.update_user(user)
        services.relay.send_to_user(message_id, user.id, services.replies.already_in_chat)
      end
    end

    def new_user(id : UserID, username : String?, fullname : String, message_id : MessageID, services : Services)
      unless services.config.registration_open
        return services.relay.send_to_user(nil, id, services.replies.registration_closed)
      end

      if services.database.no_users?
        services.database.add_user(id, username, fullname, services.access.max_rank)
      else
        services.database.add_user(id, username, fullname, services.config.default_rank)
      end

      if motd = services.database.get_motd
        services.relay.send_to_user(nil, id, motd)
      end

      if services.config.pseudonymous
        services.relay.send_to_user(message_id, id, services.replies.joined_pseudonym)
      else
        services.relay.send_to_user(message_id, id, services.replies.joined)
      end

      log = Format.substitute_message(services.logs.joined, {
        "id"   => id.to_s,
        "name" => username || fullname,
      })

      services.relay.log_output(log)
    end
  end
end
