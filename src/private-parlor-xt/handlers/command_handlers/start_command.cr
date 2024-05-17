require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "start", config: "enable_start")]
  # A command used to join the bot and start receiving messages
  class StartCommand < CommandHandler
    # Adds the user from the given *message* to the bot if he is not in the database; rejoins users who have previously joined the chat.
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless info = message.from

      if text = message.text || message.caption
        return unless text.starts_with?('/')
      end

      if user = services.database.get_user(info.id.to_i64)
        existing_user(user, info.username, info.full_name, message.message_id.to_i64, services)
      else
        new_user(info.id.to_i64, info.username, info.full_name, message.message_id.to_i64, services)
      end
    end

    # Handles users attempting to rejoin if they are already in the database
    def existing_user(user : User, username : String?, fullname : String, message_id : MessageID, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.contact(services.config.blacklist_contact, services.replies),
          "reason"  => Format.reason(user.blacklist_reason, services.replies),
        })

        services.relay.send_to_user(nil, user.id, response)
      elsif user.left?
        user.rejoin
        user.update_names(username, fullname)
        user.set_active
        services.database.update_user(user)

        services.relay.send_to_user(ReplyParameters.new(message_id), user.id, services.replies.rejoined)

        log = Format.substitute_message(services.logs.rejoined, {"id" => user.id.to_s, "name" => user.formatted_name})

        services.relay.log_output(log)
      else
        user.update_names(username, fullname)
        user.set_active

        services.database.update_user(user)
        services.relay.send_to_user(ReplyParameters.new(message_id), user.id, services.replies.already_in_chat)
      end
    end

    # Adds the user with the given *id* to the database if registration is open.
    def new_user(id : UserID, username : String?, fullname : String, message_id : MessageID, services : Services) : Nil
      unless services.config.registration_open
        return services.relay.send_to_user(nil, id, services.replies.registration_closed)
      end

      if services.database.no_users?
        user = services.database.add_user(id, username, fullname, services.access.max_rank)
      else
        user = services.database.add_user(id, username, fullname, services.config.default_rank)
      end

      if motd = services.database.motd
        services.relay.send_to_user(nil, id, motd)
      end

      if services.config.pseudonymous
        services.relay.send_to_user(ReplyParameters.new(message_id), id, services.replies.joined_pseudonym)
      else
        services.relay.send_to_user(ReplyParameters.new(message_id), id, services.replies.joined)
      end

      log = Format.substitute_message(services.logs.joined, {
        "id"   => id.to_s,
        "name" => user.formatted_name,
      })

      services.relay.log_output(log)
    end
  end
end
