require "./constants.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  module AlbumHelpers
    class Album
      property message_ids : Array(MessageID)
      property media : Array(Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument)

      # Creates and instance of `Album`, representing a prepared media group to queue and relay
      #
      # ## Arguments:
      #
      # `msid`
      # :     the message ID of the first media file in the album
      #
      # `media`
      # :     the media type corresponding with the given MSID
      def initialize(message : MessageID, media : Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument)
        @message_ids = [message]
        @media = [media]
      end
    end

    def get_album_input(message : Tourmaline::Message, caption : String, entities : Array(Tourmaline::MessageEntity), allow_spoilers : Bool? = false) : Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument | Nil
      if media = message.photo.last?
        Tourmaline::InputMediaPhoto.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && allow_spoilers)
      elsif media = message.video
        Tourmaline::InputMediaVideo.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && allow_spoilers)
      elsif media = message.audio
        Tourmaline::InputMediaAudio.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil)
      elsif media = message.document
        Tourmaline::InputMediaDocument.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil)
      else
        return
      end
    end

    def relay_album(album : Album, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, history : History, relay : Relay)
      cached_messages = Array(MessageID).new

      album.message_ids.each do |msid|
        cached_messages << history.new_message(user.id, msid)
      end

      relay.send_album(
        cached_messages,
        user,
        receivers,
        reply_msids,
        album.media,
      )
    end
  end
end
