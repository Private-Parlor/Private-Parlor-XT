require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["ksign", "ks"], config: "enable_karma_sign")]
  # Processes karma sign messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class KarmaSignCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services)
      message, user = get_message_and_user(message, services)
      return unless message && user

      return if message.forward_origin

      if services.config.karma_levels.empty?
        return
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

      current_level = get_karma_level(services.config.karma_levels, user)

      text, entities = Format.format_karma_sign(current_level, arg, entities)

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

    def get_karma_level(karma_levels : Hash(Int32, String), user : User) : String
      current_level = ""

      if user.karma <= karma_levels.first_key
        return karma_levels.first_value
      end

      if user.karma >= karma_levels.last_key
        return karma_levels.last_value
      end

      karma_levels.each_cons_pair do |lower, higher|
        if lower[0] <= user.karma && user.karma < higher[0]
          return current_level = lower[1]
        end
      end

      current_level
    end
  end
end
