require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["tsign", "ts"], config: "enable_tripsign")]
  # Processes tripcode sign messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class TripcodeSignCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      unless tripcode = user.tripcode
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_tripcode_set)
      end

      return unless authorized?(user, message, :TSign, services)

      text, entities = Format.valid_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless Robot9000.checks(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = update_entities(text, entities, arg, message)

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
