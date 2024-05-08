require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  # Annotation for Telegram command handlers
  # 
  # ## Keys and Values:
  #
  # `command`
  # :     A `StringLiteral` or an array of `StringLiteral` containing the text that will activate the handler when the text follows a forward slash '/'.
  #       If using an array of `StringLiteral` to define aliases, the first element in the array will be used for `CommandDescriptions` and registering the command description with BotFather.
  #
  # `config`
  # :     `String`, the name of the `Config` member that enables this handler.
  #       Handlers should be configurable, though a value is not required here to compile or be used in the program.
  annotation RespondsTo
  end

  # A base class for handling a Telegram command
  # 
  # Handlers that are meant to respond to commands (messages that start with '/') should inherit this class, 
  # and include a `RespondsTo` annotation to have it be usable by the bot.
  abstract class CommandHandler < Handler

    # Gets the `User` with updated names from the given *message* and returns it if the message is a command, the user exists, and the user is not blacklisted
    def get_user_from_message(message : Tourmaline::Message, services : Services) : User?
      return unless info = message.from

      if text = message.text || message.caption
        return unless text.starts_with?('/')
      end

      unless user = services.database.get_user(info.id.to_i64)
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      return deny_user(user, services) unless user.can_use_command?

      user.update_names(info.username, info.full_name)

      user
    end

    # Queues a system reply when the user is blacklisted and cannot use a command
    def deny_user(user : User, services : Services) : Nil
      return unless user.blacklisted?

      response = Format.substitute_reply(services.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
        "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
      })

      services.relay.send_to_user(nil, user.id, response)
    end

    # Checks if the user's `Rank` contain the given `CommandPermissions`
    # 
    # Returns `true` if it does, `false` otherwise
    def authorized?(user : User, message : Tourmaline::Message, permission : CommandPermissions, services : Services) : Bool
      unless services.access.authorized?(user.rank, permission)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.command_disabled)
        return false
      end

      true
    end

    # Checks if the user's `Rank` contains any of the given `CommandPermissions`
    # 
    # If it does, it returns the one `CommandPermissions`
    # Returns `nil` otherwise
    def authorized?(user : User, message : Tourmaline::Message, services : Services, *permissions : CommandPermissions) : CommandPermissions?
      if authority = services.access.authorized?(user.rank, *permissions)
        authority
      else
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.command_disabled)
      end
    end

    # Deletes the message group associated with the given *message* ID in the chat and from the `History`
    # 
    # Returns the original `MessageID` of the associated message group
    def delete_messages(message : MessageID, user : UserID, debug_enabled : Bool?, services : Services) : MessageID?
      reply_msids = services.history.get_all_receivers(message)

      unless debug_enabled
        reply_msids.delete(user)
      end

      reply_msids.each do |receiver, receiver_message|
        services.relay.delete_message(receiver, receiver_message)
      end

      services.history.delete_message_group(message)
    end

    # Removes the bot command message entity from *entities* and subtracts the index of the *arg* start from the offset of each message entity in *entities*
    # 
    # Returns an array of updated `Tourmaline::MessageEntity`
    def update_entities(text : String, entities : Array(Tourmaline::MessageEntity), arg : String) : Array(Tourmaline::MessageEntity)
      if command_entity = entities.find { |item| item.type == "bot_command" && item.offset == 0 }
        entities = entities - [command_entity]
      end

      # Remove command and all whitespace before the start of arg
      arg_offset = text[...text.index(arg)].to_utf16.size
      Format.reset_entities(entities, arg_offset)
    end
  end
end
