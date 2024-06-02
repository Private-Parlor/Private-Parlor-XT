require "../spec_helper.cr"

module PrivateParlorXT
  class MockRelay < Relay
    @queue : MessageQueue = MockMessageQueue.new

    def send_to_user(reply_message : ReplyParameters?, user : UserID, text : String, reply_markup : Tourmaline::InlineKeyboardMarkup? = nil) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue_priority(
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

    def send_text(params : PrivateParlorXT::RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_photo(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_animation(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_video(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_audio(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_voice(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_document(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_poll_copy(reply : MessageID?, user : User, effect : String?, poll : Tourmaline::Poll) : Tourmaline::Message
      bot_user = Tourmaline::User.new(12345678, true, "spec")

      Tourmaline::Message.new(
        message_id: reply + 1,
        date: Time.utc,
        chat: Tourmaline::Chat.new(bot_user.id, "private"),
        poll: poll,
        from: bot_user
      )
    end

    def send_forward(params : RelayParameters, message : MessageID) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_video_note(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_sticker(params : RelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_album(params : AlbumHelpers::AlbumRelayParameters) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
        params.origins,
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

    def send_venue(params : RelayParameters, venue : Tourmaline::Venue) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_location(params : RelayParameters, location : Tourmaline::Location) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def send_contact(params : RelayParameters, contact : Tourmaline::Contact) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue(
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

    def pin_message(user : UserID, message : MessageID) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue_priority(
        user,
        ReplyParameters.new(message),
        "",
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.pin_chat_message(receiver, reply.message_id)
        }
      )
    end

    def unpin_message(user : UserID, message : MessageID? = nil) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      if message
        message = ReplyParameters.new(message)
      else
        message = nil
      end

      queue.enqueue_priority(
        user,
        message,
        "",
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          if reply
            @client.unpin_chat_message(receiver, reply.message_id)
          else
            @client.unpin_chat_message(receiver, nil)
          end
        }
      )
    end

    def edit_message_media(user : UserID, media : Tourmaline::InputMedia, message : MessageID) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue_priority(
        user,
        ReplyParameters.new(message),
        "#{media.media};#{media.type};#{media.caption};#{media.has_spoiler?}",
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.edit_message_media(media, receiver, reply.message_id)
          # We don't care about the result, so return a boolean
          # to satisfy type requirements
          true
        }
      )
    end

    def edit_message_text(user : UserID, text : String, markup : Tourmaline::InlineKeyboardMarkup?, message : MessageID) : Nil
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.enqueue_priority(
        user,
        ReplyParameters.new(message),
        text,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.edit_message_text(text, receiver, reply.message_id, reply_markup: markup)
          true
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
