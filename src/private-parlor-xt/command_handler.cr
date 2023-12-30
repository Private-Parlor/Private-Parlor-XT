require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  annotation RespondsTo
  end

  abstract class CommandHandler < Handler
    def get_message_and_user(message : Tourmaline::Message, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless info = message.from
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
        return message, nil
      end

      unless user.can_use_command?
        deny_user(user, services)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

    private def deny_user(user : User, services : Services) : Nil
      return unless user.blacklisted?

      response = Format.substitute_reply(services.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
        "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
      })

      services.relay.send_to_user(nil, user.id, response)
    end

    def authorized?(user : User, message : Tourmaline::Message, permission : CommandPermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, permission)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.command_disabled)
        return false
      end

      true
    end

    def authorized?(user : User, message : Tourmaline::Message, services : Services, *permissions : CommandPermissions) : CommandPermissions?
      if authority = services.access.authorized?(user.rank, *permissions)
        authority
      else
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.command_disabled)
      end
    end

    def delete_messages(message : MessageID, user : UserID, debug_enabled : Bool?, priority : Bool, services : Services) : MessageID?
      if reply_msids = services.history.get_all_receivers(message)
        unless debug_enabled
          reply_msids.delete(user)
        end

        if priority
          reply_msids.each do |receiver, receiver_message|
            services.relay.delete_message(receiver, receiver_message)
          end
        else
          reply_msids.each do |receiver, receiver_message|
            services.relay.remove_message(receiver, receiver_message)
          end
        end

        services.history.delete_message_group(message)
      end
    end

    def update_entities(text : String, entities : Array(Tourmaline::MessageEntity), arg : String, message : Tourmaline::Message) : Array(Tourmaline::MessageEntity)
      if command_entity = entities.find { |item| item.type == "bot_command" && item.offset == 0 }
        entities = entities - [command_entity]
      end

      # Remove command and all whitespace before the start of arg
      arg_offset = text[...text.index(arg)].to_utf16.size
      Format.reset_entities(entities, arg_offset)
    end
  end
end
