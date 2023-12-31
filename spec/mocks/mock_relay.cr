require "../spec_helper.cr"

module PrivateParlorXT
  class MockRelay < Relay
    @queue : MessageQueue = MockMessageQueue.new

    def send_to_user(reply_message : ReplyParameters?, user : UserID, text : String)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue_priority(
        user,
        reply_message,
        text,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_message(
            receiver,
            text,
            link_preview_options: Tourmaline::LinkPreviewOptions.new,
            reply_parameters: reply
          )
        }
      )
    end

    def send_text(params : PrivateParlorXT::RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.text,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_message(
            receiver,
            params.text,
            parse_mode: nil,
            entities: params.entities,
            link_preview_options: params.link_preview_options,
            reply_parameters: reply
          )
        }
      )
    end

    def send_photo(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_photo(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            has_spoiler: params.spoiler,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_animation(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_animation(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            has_spoiler: params.spoiler,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_video(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_video(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            has_spoiler: params.spoiler,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_audio(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_audio(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_voice(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_audio(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_document(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        params.entities,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_document(
            receiver,
            params.media,
            caption: params.text,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: params.entities,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_poll_copy(reply : MessageID?, user : User, poll : Tourmaline::Poll)
      PrivateParlorXT.create_message(
        reply + 1,
        Tourmaline::User.new(12345678, true, "spec"),
        poll: poll,
      )
    end

    def send_forward(params : RelayParameters, message : MessageID)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        message.to_s,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, _reply : ReplyParameters?) {
          @client.forward_message(
            receiver,
            params.sender,
            message,
          )
        }
      )
    end

    def send_video_note(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_video_note(
            receiver,
            params.media,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_sticker(params : RelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        params.media,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_sticker(
            receiver,
            params.media,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_album(params : AlbumHelpers::AlbumRelayParameters)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_messages,
        params.sender,
        params.receivers,
        params.replies,
        params.media.first.media,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_media_group(
            receiver,
            params.media,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_venue(params : RelayParameters, venue : Tourmaline::Venue)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        venue.address,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_venue(
            receiver,
            latitude: venue.location.latitude,
            longitude: venue.location.longitude,
            title: venue.title,
            address: venue.address,
            foursquare_id: venue.foursquare_id,
            foursquare_type: venue.foursquare_type,
            google_place_id: venue.google_place_id,
            google_place_type: venue.google_place_type,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_location(params : RelayParameters, location : Tourmaline::Location)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        "#{location.latitude}, #{location.longitude}",
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_location(
            receiver,
            latitude: location.latitude,
            longitude: location.longitude,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_contact(params : RelayParameters, contact : Tourmaline::Contact)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        contact.phone_number,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_contact(
            receiver,
            phone_number: contact.phone_number,
            first_name: contact.first_name,
            last_name: contact.last_name,
            vcard: contact.vcard,
            reply_parameters: reply,
          )
        }
      )
    end

    def empty_queue : Array(MockQueuedMessage)
      arr = [] of MockQueuedMessage
      while msg = @queue.get_message
        if msg.is_a?(MockQueuedMessage)
          arr << msg
        end
      end

      arr
    end
  end
end
