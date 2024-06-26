require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["ksign", "ks"], config: "enable_karma_sign")]
  # Processes karma sign messages before an `UpdateHandler` gets them
  #
  # This handler expects the command handlers to be registered before the update handlers
  class KarmaSignCommand < CommandHandler
    # Preformats the given *message* with a karma level signature if the *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return if message.forward_origin

      karma_levels = services.config.karma_levels

      return if karma_levels.empty?

      text, entities = Format.validate_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless unique?(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = remove_command_entity(text, entities, arg)

      current_level = get_karma_level(karma_levels, user)

      text, entities = karma_sign(current_level, arg, entities)

      if message.text
        message.text = text
        message.entities = entities
      elsif message.caption
        message.caption = text
        message.caption_entities = entities
      end

      message.preformatted = true
    end

    # Checks if the user is spamming karma level signatures
    #
    # Returns `true` if the user is spamming karma level signatures or unformatted text is spammy, returns `false` otherwise
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

    # Returns the name of the karma level whose range contains the *user's* karma
    def get_karma_level(karma_levels : Hash(Range(Int32, Int32), String), user : User) : String
      karma_levels.find({(..), ""}) { |range, _| range === user.karma }[1]
    end

    # Format the karma level sign based on the given *level* appending the signature to *arg*
    def karma_sign(level : String, arg : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      signature = "t. #{level}"

      signature_size = signature.to_utf16.size

      entities.concat([
        Tourmaline::MessageEntity.new("bold", arg.to_utf16.size + 1, signature_size),
        Tourmaline::MessageEntity.new("italic", arg.to_utf16.size + 1, signature_size),
      ])

      return "#{arg} #{signature}", entities
    end
  end
end
