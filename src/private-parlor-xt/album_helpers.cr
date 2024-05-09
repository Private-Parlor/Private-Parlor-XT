require "./constants.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  module AlbumHelpers
    WAIT_TIME = 500.milliseconds

    alias AlbumMedia = Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument

    # A set of relay parameters associated with an album
    class AlbumRelayParameters
      getter original_messages : Array(MessageID)
      getter sender : UserID
      getter receivers : Array(UserID)
      getter media : Array(AlbumMedia)
      getter replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters

      def initialize(
        @original_messages : Array(MessageID),
        @sender : UserID,
        @receivers : Array(UserID),
        @media : Array(AlbumMedia),
        @replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters
      )
      end
    end

    # An object representing a prepared media group to queue and relay
    class Album
      property message_ids : Array(MessageID) = [] of MessageID
      property media : Array(AlbumMedia) = [] of AlbumMedia

      # Creates and instance of `Album`
      #
      # ## Arguments:
      #
      # `message`
      # :     the `MessageID` of the first media file in the album
      #
      # `media`
      # :     the media type corresponding with the given MSID
      def initialize(message : MessageID, media : AlbumMedia)
        @message_ids << message
        @media << media
      end
    end

    # Returns the `Tourmaline::InputMedia` from the media in the given *message*, if available.
    # 
    # Returns `nil` if there was no media in the *message* to create a `Tourmaline::InputMedia`
    def get_album_input(message : Tourmaline::Message, caption : String, entities : Array(Tourmaline::MessageEntity), allow_spoilers : Bool? = false) : AlbumMedia?
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

    # Relays the given *album* after an arbitrary amount of time, waiting for the rest of the media group updates to come in
    # 
    # Returns early if the album is already queued for relaying, and adds the *input* to the Album object.
    def relay_album(albums : Hash(String, Album), album : String, message_id : MessageID, input : AlbumMedia, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, ReplyParameters), services : Services)
      if albums[album]?
        albums[album].message_ids << message_id
        albums[album].media << input
        return
      end

      media_group = Album.new(message_id, input)
      albums.merge!({album => media_group})

      # Wait an arbitrary amount of time for Telegram MediaGroup updates to come in before relaying the album.
      Tasker.in(WAIT_TIME) {
        next unless prepared_album = albums.delete(album)

        cached_messages = Array(MessageID).new

        prepared_album.message_ids.each do |msid|
          cached_messages << services.history.new_message(user.id, msid)
        end

        services.relay.send_album(AlbumRelayParameters.new(
          original_messages: cached_messages,
          sender: user.id,
          receivers: receivers,
          replies: reply_msids,
          media: prepared_album.media,
        )
        )
      }
    end
  end
end
