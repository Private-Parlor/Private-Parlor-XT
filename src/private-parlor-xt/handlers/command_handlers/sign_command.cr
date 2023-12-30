require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["sign", "s"], config: "enable_sign")]
  # Processes sign messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class SignCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      message, user = get_message_and_user(message, services)
      return unless message && user

      return if message.forward_origin

      return unless authorized?(user, message, :Sign, services)

      if (chat = message.sender_chat) && chat.has_private_forwards?
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.private_sign)
      end

      text, entities = Format.valid_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless Robot9000.text_check(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = update_entities(text, entities, arg, message)

      text, entities = Format.format_user_sign(user.get_formatted_name, user.id, arg, entities)

      if message.text
        message.text = text
        message.entities = entities
      elsif message.caption
        message.caption = text
        message.caption_entities = entities
      end

      message.preformatted = true
    end

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
  end
end
