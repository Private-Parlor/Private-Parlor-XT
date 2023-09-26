require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["tsign", "ts"], config: "enable_tripsign")]
  # Processes tripcode sign messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class TripcodeSignCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless is_authorized?(user, message, :TSign, services)

      unless tripcode = user.tripcode
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.no_tripcode_set)
      end

      return unless text = message.text || message.caption

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.missing_args)
      end

      return if is_spamming?(user, message, arg, services)

      # TODO: Add R9K check and write hooks

      entities = message.entities.empty? ? message.caption_entities : message.entities

      if command_entity = entities.find { |item| item.type == "bot_command" && item.offset == 0 }
        entities = entities - [command_entity]
      end

      # Remove command and all whitespace before the start of arg
      arg_offset = text[...text.index(arg)].to_utf16.size
      entities = Format.reset_entities(entities, arg_offset)

      name, tripcode = Format.generate_tripcode(tripcode, services.config.tripcode_salt)
      text, entities = Format.format_tripcode_sign(name, tripcode, entities)

      text = text + arg

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
