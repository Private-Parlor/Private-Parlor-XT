require "../../handlers.cr"
require "./album_handler.cr"
require "tasker"
require "tourmaline"

module PrivateParlorXT

  class RegularForwardHandler < UpdateHandler
    @albums : Hash(String, AlbumHandler::Album) = {} of String => AlbumHandler::Album

    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Forward)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "forward"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      if (poll = message.poll) && (!poll.is_anonymous?)
        relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.deanon_poll)
      end

      text = message.text || message.caption || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      # TODO: Add R9K check hook

      if spam
        unless (album = message.media_group_id) && @albums[album]?
          if spam.spammy_forward?(user.id)
            return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
          end
        end
      end

      # TODO: Add R9K write hook

      new_message = history.new_message(user.id, message.message_id.to_i64)
      
      user.set_active
      database.update_user(user)

      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      # Foward regular forwards, otherwise add header to text and offset entities then send as a captioned type

      if Format.regular_forward?(text, entities)
        return relay.send_forward(
          new_message,
          user,
          receivers,
          message.message_id.to_i64
        )
      end

      header, entities = Format.get_forward_header(message, entities)
      unless header
        return relay.send_forward(
          new_message,
          user,
          receivers,
          message.message_id.to_i64
        )
      end

      text = header + text

      relay_regular_forward(message, text, entities, new_message, user, receivers, relay)
    end

    def relay_regular_forward(message : Tourmaline::Message, text : String, entities : Array(Tourmaline::MessageEntity), cached_message : MessageID, user : User, receivers : Array(UserID), relay : Relay)
      if message.text
        relay.send_text(
          cached_message,
          user,
          receivers,
          nil,
          text,
          entities,
        )
      elsif album = message.media_group_id
        # TODO: Add regular forward album handler
      elsif file = message.animation
        relay.send_animation(
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
        relay.send_document(
          cached_message,
          user,
          receivers,
          nil,
          file.file_id,
          text,
          entities,
        )
      elsif file = message.video
        relay.send_video(
          cached_message,
          user,
          receivers,
          nil,
          file.file_id,
          text,
          entities,
          message.has_media_spoiler?,
        )
      elsif file = message.photo
        relay.send_photo(
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
        relay.send_forward(
          cached_message,
          user,
          receivers,
          message.message_id.to_i64
        )
      end
    end
  end
end