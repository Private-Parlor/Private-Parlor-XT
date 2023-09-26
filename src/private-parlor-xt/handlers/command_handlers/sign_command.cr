require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["sign", "s"], config: "enable_sign")]
  # Processes sign messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class SignCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless is_authorized?(user, message, :Sign, services)

      if (chat = context.api.get_chat(user.id)) && chat.has_private_forwards?
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.private_sign)
      end

      return unless text = message.text || message.caption

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.missing_args) 
      end

      return if is_spamming?(user, message, arg, services)

      entities = message.entities.empty? ? message.caption_entities : message.entities

      if command_entity = entities.find { |item| item.type == "bot_command" && item.offset == 0}
        entities = entities - [command_entity]
      end

      # Remove command and all whitespace before the start of arg
      arg_offset = text[...text.index(arg)].to_utf16.size
      entities = Format.reset_entities(entities, arg_offset)

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

    def is_spamming?(user : User, message : Tourmaline::Message, arg : String, services : Services) : Bool
      return false unless spam = services.spam

      if message.text && spam.spammy_text?(user.id, arg)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      if spam.spammy_sign?(user.id, services.config.sign_limit_interval)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      return false
    end
  end
end