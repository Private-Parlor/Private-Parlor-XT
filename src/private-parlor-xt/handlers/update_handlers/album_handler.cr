require "../../handlers.cr"
require "../../constants.cr"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  @[On(update: :MediaGroup, config: "relay_media_group")]
  class AlbumHandler < UpdateHandler
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

    @entity_types : Array(String)
    @linked_network : Hash(String, String) = {} of String => String
    @allow_spoilers : Bool? = false
    @albums : Hash(String, Album) = {} of String => Album

    def initialize(config : Config)
      @entity_types = config.entities
      @linked_network = config.linked_network
      @allow_spoilers = config.media_spoilers
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      return if message.forward_date
      return unless album = message.media_group_id

      unless access.authorized?(user.rank, :MediaGroup)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "media_group"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      caption, entities = check_text(message.caption ||= "", user, message, message.caption_entities, relay, locale)

      # TODO: Add R9K check hook

      # TODO: Add pseudonymous hook

      if spam && @albums[album]? == nil
        if spam.spammy_album?(user.id)
          return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
        end
      end

      if reply = message.reply_to_message
        reply_msids = history.get_all_receivers(reply.message_id.to_i64)

        if reply_msids.empty?
          return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.not_in_cache)
        end
      end

      user.set_active
      database.update_user(user)

      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      return unless input = get_album_input(message, caption, entities)

      if @albums[album]?
        @albums[album].message_ids << message.message_id.to_i64
        @albums[album].media << input
        return
      end

      media_group = Album.new(message.message_id.to_i64, input)
      @albums.merge!({album => media_group})

      # Wait an arbitrary amount of time for Telegram MediaGroup updates to come in before relaying the album.
      Tasker.in(500.milliseconds) {
        unless temp_album = @albums.delete(album)
          next
        end

        cached_messages = Array(MessageID).new

        temp_album.message_ids.each do |msid|
          cached_messages << history.new_message(user.id, msid)
        end

        temp_album.media.each do |item|
          item.to_pretty_json
        end

        relay.send_album(
          cached_messages,
          user,
          receivers,
          reply_msids,
          temp_album.media,
        )
      }
    end

    private def get_album_input(message : Tourmaline::Message, caption : String, entities : Array(Tourmaline::MessageEntity)) : Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument | Nil
      if media = message.photo.last?
        Tourmaline::InputMediaPhoto.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && @allow_spoilers)
      elsif media = message.video
        Tourmaline::InputMediaVideo.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil, has_spoiler: message.has_media_spoiler? && @allow_spoilers)
      elsif media = message.audio
        Tourmaline::InputMediaAudio.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil)
      elsif media = message.document
        Tourmaline::InputMediaDocument.new(media.file_id, caption: caption, caption_entities: entities, parse_mode: nil)
      else
        return
      end
    end
  end
end
