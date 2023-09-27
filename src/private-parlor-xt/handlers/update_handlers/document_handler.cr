require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Document, config: "relay_document")]
  class DocumentHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Document, services)

      return if spamming?(user, message, services)

      return unless document = message.document

      caption, entities = get_caption_and_entities(message, user, services)
      return if message.caption && caption.empty?

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      return unless r9k_checks(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_document(
        new_message,
        user,
        receivers,
        reply_msids,
        document.file_id,
        caption,
        entities,
      )
    end

    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_date
      return false if message.media_group_id
      return false if message.animation

      true
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_document?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.spamming)
        return true
      end

      false
    end
  end
end
