require "./constants.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  module AlbumHelpers
    WAIT_TIME = 500.milliseconds

    # A set of relay parameters associated with an album
    class AlbumRelayParameters
      getter origins : Array(MessageID)
      getter sender : UserID
      getter receivers : Array(UserID)
      getter media : Array(AlbumMedia)
      getter replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters
      getter effect : String? = nil

      def initialize(
        @origins : Array(MessageID),
        @sender : UserID,
        @receivers : Array(UserID),
        @media : Array(AlbumMedia),
        @replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters,
        @effect : String? = nil
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
    def album_input(message : Tourmaline::Message, caption : String, entities : Array(Tourmaline::MessageEntity), allow_spoilers : Bool? = false) : AlbumMedia?
      if media = message.photo.last?
        Tourmaline::InputMediaPhoto.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && allow_spoilers, show_caption_above_media: message.show_caption_above_media?)
      elsif media = message.video
        Tourmaline::InputMediaVideo.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && allow_spoilers, show_caption_above_media: message.show_caption_above_media?)
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
    def relay_album(albums : Hash(String, Album), album : String, message_id : MessageID, input : AlbumMedia, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, ReplyParameters), effect : String?, services : Services) : Nil
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

        # If any item in the album is set to have its caption displayed above the media
        # then all items should be set this way as well
        if prepared_album.media.any? { |item| !item.is_a?(Tourmaline::InputMediaDocument | Tourmaline::InputMediaAudio) && item.show_caption_above_media? }
          prepared_album.media.each { |item| item.show_caption_above_media = true if item.is_a?(Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo) }
        end

        cached_messages = Array(MessageID).new

        prepared_album.message_ids.each do |msid|
          cached_messages << services.history.new_message(user.id, msid)
        end

        services.relay.send_album(
          AlbumRelayParameters.new(
            origins: cached_messages,
            sender: user.id,
            receivers: receivers,
            replies: reply_msids,
            media: prepared_album.media,
            effect: effect,
          )
        )
      }
    end
  end
end
