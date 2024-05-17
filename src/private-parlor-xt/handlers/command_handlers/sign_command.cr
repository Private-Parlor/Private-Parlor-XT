require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["sign", "s"], config: "enable_sign")]
  # Processes sign messages before an `UpdateHandler` gets them
  #
  # This handler expects the command handlers to be registered before the update handlers
  class SignCommand < CommandHandler
    # Preformats the given *message* with a username signature if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      return unless authorized?(user, message, :Sign, services)

      if (chat = services.relay.get_chat(user.id)) && chat.has_private_forwards?
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.private_sign)
      end

      text, entities = Format.validate_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless unique?(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = remove_command_entity(text, entities, arg)

      text, entities = user_sign(user.formatted_name, user.id, arg, entities)

      if message.text
        message.text = text
        message.entities = entities
      elsif message.caption
        message.caption = text
        message.caption_entities = entities
      end

      message.preformatted = true
    end

    # Checks if the user is spamming username signatures
    #
    # Returns `true` if the user is spamming username signatures or unformatted text is spammy, returns `false` otherwise
    def spamming?(user : User, message : Tourmaline::Message, arg : String, services : Services) : Bool
      return false unless spam = services.spam

      if message.text && spam.spammy_text?(user.id, arg)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      if spam.spammy_sign?(user.id, services.config.sign_limit_interval)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.sign_spam)
        return true
      end

      false
    end

    # Format the user sign based on the given *name*, appending the signature to *arg* as a text link to the user's ID
    def user_sign(name : String, id : UserID, arg : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      signature = "~~#{name}"

      signature_size = signature.to_utf16.size

      entities.concat([
        Tourmaline::MessageEntity.new(
          "text_link",
          arg.to_utf16.size + 1,
          signature_size,
          url: "tg://user?id=#{id}"
        ),
      ])

      return "#{arg} #{signature}", entities
    end
  end
end
