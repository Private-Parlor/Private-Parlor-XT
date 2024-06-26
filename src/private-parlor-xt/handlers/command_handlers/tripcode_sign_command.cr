require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["tsign", "ts"], config: "enable_tripsign")]
  # Processes tripcode sign messages before an `UpdateHandler` gets them
  #
  # This handler expects the command handlers to be registered before the update handlers
  class TripcodeSignCommand < CommandHandler
    # Preformats the given *message* with a tripcode signature header if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      unless tripcode = user.tripcode
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_tripcode_set)
      end

      return unless authorized?(user, message, :TSign, services)

      text, entities = Format.validate_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless unique?(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = remove_command_entity(text, entities, arg)

      name, tripcode = Format.generate_tripcode(tripcode, services)

      if services.config.flag_signatures
        text, entities = Format.flag_sign(name, entities)
      else
        text, entities = Format.tripcode_sign(name, tripcode, entities)
      end

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

    # Checks if the user is spamming tripcode signatures
    #
    # Returns `true` if the user is spamming tripcode signatures or unformatted text is spammy, returns `false` otherwise
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
