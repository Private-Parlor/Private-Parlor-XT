require "../../update_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Video, config: "relay_video")]
  class VideoHandler < UpdateHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return unless meets_requirements?(message)

      return unless authorized?(user, message, :Video, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      return unless video = message.video

      caption, entities = Format.get_text_and_entities(message, user, services)
      return unless caption

      reply_messages = get_reply_receivers(message, user, services)
      return unless reply_messages

      return unless Robot9000.checks(user, message, services)

      record_message_statistics(Statistics::MessageCounts::Videos, services)

      user = spend_karma(user, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_video(RelayParameters.new(
        original_message: new_message,
        sender: user.id,
        receivers: receivers,
        replies: reply_messages,
        media: video.file_id,
        text: caption,
        entities: entities,
        spoiler: services.config.allow_spoilers ? message.has_media_spoiler? : false,
      )
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      if spam.spammy_video?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_video >= 0

      return true if user.rank >= karma.cutoff_rank

      unless user.karma >= karma.karma_video
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_video.to_s,
            "type"   => "video",
          })
        )
      end

      true
    end

    def spend_karma(user : User, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_video >= 0

      return user if user.rank >= karma.cutoff_rank

      user.decrement_karma(karma.karma_video)

      user
    end
  end
end
