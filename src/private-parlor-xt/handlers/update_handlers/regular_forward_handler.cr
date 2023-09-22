require "../../handlers.cr"
require "../../album_helpers.cr"
require "tourmaline"

module PrivateParlorXT
  class RegularForwardHandler < UpdateHandler
    include AlbumHelpers

    property albums : Hash(String, Album) = {} of String => Album

    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless is_authorized?(user, message, :Forward, services)

      return if deanonymous_poll(user, message, services)

      return if is_spamming?(user, message, services)

      text = message.text || message.caption || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      # TODO: Add R9K check hook

      # TODO: Add R9K write hook

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      # Foward regular forwards, otherwise add header to text and offset entities then send as a captioned type
      if Format.regular_forward?(text, entities)
        return services.relay.send_forward(
          new_message,
          user,
          receivers,
          message.message_id.to_i64
        )
      end

      header, entities = get_header(message, entities)

      unless header
        return services.relay.send_forward(
          new_message,
          user,
          receivers,
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

    def is_spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam
      
      return false if (album = message.media_group_id) && @albums[album]?

      if spam.spammy_forward?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      false
    end

    def deanonymous_poll(user : User, message : Tourmaline::Message, services : Services) : Bool
      if (poll = message.poll) && !poll.is_anonymous?
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.deanon_poll)
        return true
      end

      false
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
        services.relay.send_text(
          cached_message,
          user,
          receivers,
          nil,
          text,
          entities,
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
          nil, 
          services
        )
      elsif file = message.animation
        services.relay.send_animation(
          cached_message,
          user,
          receivers,
          nil,
          file.file_id,
          text,
          entities,
          message.has_media_spoiler?,
        )
      elsif file = message.document
        services.relay.send_document(
          cached_message,
          user,
          receivers,
          nil,
          file.file_id,
          text,
          entities,
        )
      elsif file = message.video
        services.relay.send_video(
          cached_message,
          user,
          receivers,
          nil,
          file.file_id,
          text,
          entities,
          message.has_media_spoiler?,
        )
      elsif (file = message.photo) && file.last?
        services.relay.send_photo(
          cached_message,
          user,
          receivers,
          nil,
          file.last.file_id,
          text,
          entities,
          message.has_media_spoiler?,
        )
      else
        services.relay.send_forward(
          cached_message,
          user,
          receivers,
          message.message_id.to_i64
        )
      end
    end
  end
end
