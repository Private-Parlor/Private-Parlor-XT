require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Document, config: "relay_document")]
  class DocumentHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Document, services)

      return if spamming?(user, message, services)

      return unless document = message.document

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_exists?(message, reply_messages, user, services)

      return unless Robot9000.checks(user, message, services)

      return unless user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_document(RelayParameters.new(
        original_message: new_message,
        sender: user.id,
        receivers: receivers,
        replies: reply_messages,
        media: document.file_id,
        text: caption,
        entities: entities,
      )
      )
    end

    def meets_requirements?(message : Tourmaline::Message) : Bool
      return false if message.forward_origin
      return false if message.media_group_id
      return false if message.animation

      true
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_document?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def spend_karma(user : User, services : Services) : User?
      return user unless karma = services.karma

      return user if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_document
        # TODO: Add locale entry
        return
      end

      if karma.karma_document >= 0
        user.decrement_karma(karma.karma_document)
      end

      user
    end
  end
end
