require "../../update_handler.cr"
require "../../album_helpers.cr"
require "tourmaline"

module PrivateParlorXT
  class RegularForwardHandler < UpdateHandler
    include AlbumHelpers

    property albums : Hash(String, Album) = {} of String => Album

    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Forward, services)

      return if deanonymous_poll(user, message, services)

      return unless has_sufficient_karma?(user, message, services)

      return if spamming?(user, message, services)

      text = message.text || message.caption || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      return unless Robot9000.forward_checks(user, message, services)

      user = spend_karma(user, message, services)

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      record_message_statistics(Statistics::MessageCounts::Forwards, services)

      # Foward regular forwards, otherwise add header to text and offset entities then send as a captioned type
      if Format.regular_forward?(text, entities)
        return services.relay.send_forward(RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
        ),
          message.message_id.to_i64
        )
      end

      header, entities = get_header(message, entities)

      unless header
        return services.relay.send_forward(RelayParameters.new(
          original_message: new_message,
          sender: user.id,
          receivers: receivers,
        ),
          message.message_id.to_i64
        )
      end

      text = header + text

      relay_regular_forward(
        message,
        text,
        entities,
        new_message,
        user,
        receivers,
        services,
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam

      return false if (album = message.media_group_id) && @albums[album]?

      if spam.spammy_forward?(user.id)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def deanonymous_poll(user : User, message : Tourmaline::Message, services : Services) : Bool
      if (poll = message.poll) && !poll.is_anonymous?
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.deanon_poll)
        return true
      end

      false
    end

    def has_sufficient_karma?(user : User, message : Tourmaline::Message, services : Services) : Bool?
      return true unless karma = services.karma

      return true unless karma.karma_forwarded_message >= 0

      return true if user.rank >= karma.cutoff_rank

      return true if (album = message.media_group_id) && @albums[album]?

      unless user.karma >= karma.karma_forwarded_message
        return services.relay.send_to_user(
          ReplyParameters.new(message.message_id),
          user.id,
          Format.substitute_reply(services.replies.insufficient_karma, {
            "amount" => karma.karma_forwarded_message.to_s,
            "type"   => "forward",
          })
        )
      end

      true
    end

    def spend_karma(user : User, message : Tourmaline::Message, services : Services) : User
      return user unless karma = services.karma

      return user unless karma.karma_forwarded_message >= 0

      return user if user.rank >= karma.cutoff_rank

      return user if (album = message.media_group_id) && @albums[album]?

      user.decrement_karma(karma.karma_forwarded_message)

      user
    end

    def get_header(message : Tourmaline::Message, entities : Array(Tourmaline::MessageEntity)) : Tuple(String?, Array(Tourmaline::MessageEntity))
      if (album = message.media_group_id) && @albums[album]?
        return "", [] of Tourmaline::MessageEntity
      else
        Format.get_forward_header(message, entities)
      end
    end

    def relay_regular_forward(message : Tourmaline::Message, text : String, entities : Array(Tourmaline::MessageEntity), cached_message : MessageID, user : User, receivers : Array(UserID), services : Services)
      if message.text
        services.relay.send_text(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          text: text,
          entities: entities,
        )
        )
      elsif album = message.media_group_id
        return unless input = get_album_input(message, text, entities)

        relay_album(
          @albums,
          album,
          message.message_id.to_i64,
          input,
          user,
          receivers,
          {} of UserID => ReplyParameters,
          services
        )
      elsif file = message.animation
        services.relay.send_animation(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          media: file.file_id,
          text: text,
          entities: entities,
          spoiler: message.has_media_spoiler?,
        )
        )
      elsif file = message.audio
        services.relay.send_audio(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          media: file.file_id,
          text: text,
          entities: entities,
        )
        )
      elsif file = message.document
        services.relay.send_document(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          media: file.file_id,
          text: text,
          entities: entities,
        )
        )
      elsif file = message.video
        services.relay.send_video(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          media: file.file_id,
          text: text,
          entities: entities,
          spoiler: message.has_media_spoiler?,
        )
        )
      elsif (file = message.photo) && file.last?
        file = file.last
        services.relay.send_photo(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
          media: file.file_id,
          text: text,
          entities: entities,
          spoiler: message.has_media_spoiler?,
        )
        )
      else
        services.relay.send_forward(RelayParameters.new(
          original_message: cached_message,
          sender: user.id,
          receivers: receivers,
        ),
          message.message_id.to_i64
        )
      end
    end
  end
end
