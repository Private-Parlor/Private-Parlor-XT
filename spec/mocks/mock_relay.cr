require "../spec_helper.cr"

module PrivateParlorXT
  class MockRelay < Relay
    @queue : MessageQueue = MockMessageQueue.new

    def send_to_user(reply_message : MessageID?, user : UserID, text : String)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue_priority(
        user,
        reply_message,
        text,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_message(
            receiver,
            text,
            disable_web_page_preview: false,
            reply_to_message_id: reply)
        }
      )
    end

    def send_text(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, text : String, entities : Array(Tourmaline::MessageEntity))
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        text,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_message(
            receiver,
            text,
            parse_mode: nil,
            entities: entities,
            disable_web_page_preview: false,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_photo(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, photo : String, caption : String, entities : Array(Tourmaline::MessageEntity), spoiler : Bool?)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        photo,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_photo(
            receiver,
            photo,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            has_spoiler: spoiler,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_animation(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, animation : String, caption : String, entities : Array(Tourmaline::MessageEntity), spoiler : Bool?)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        animation,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_animation(
            receiver,
            animation,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            has_spoiler: spoiler,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_video(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, video : String, caption : String, entities : Array(Tourmaline::MessageEntity), spoiler : Bool?)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        video,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_video(
            receiver,
            video,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            has_spoiler: spoiler,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_audio(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, audio : String, caption : String, entities : Array(Tourmaline::MessageEntity))
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        audio,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_audio(
            receiver,
            audio,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_voice(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, voice : String, caption : String, entities : Array(Tourmaline::MessageEntity))
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        voice,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_audio(
            receiver,
            voice,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_document(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, document : String, caption : String, entities : Array(Tourmaline::MessageEntity))
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        document,
        entities,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_document(
            receiver,
            document,
            caption: caption,
            parse_mode: Tourmaline::ParseMode::None,
            caption_entities: entities,
            reply_to_message_id: reply,
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

    def send_forward(origin : MessageID, user : User, receivers : Array(UserID), message : MessageID)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        nil,
        message.to_s,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, _reply : MessageID?) {
          @client.forward_message(
            receiver,
            user.id,
            message,
          )
        }
      )
    end

    def send_video_note(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, video_note : String)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        video_note,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_video_note(
            receiver,
            video_note,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_sticker(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, sticker_file : String)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        sticker_file,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_sticker(
            receiver,
            sticker_file,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_album(origins : Array(MessageID), user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, media : Array(Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument))
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origins,
        user.id,
        receivers,
        reply_msids,
        media.first.media,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_media_group(
            receiver,
            media,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_venue(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, venue : Tourmaline::Venue)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        venue.address,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
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
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_location(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, location : Tourmaline::Location)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        "#{location.latitude}, #{location.longitude}",
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_location(
            receiver,
            latitude: location.latitude,
            longitude: location.longitude,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def send_contact(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, contact : Tourmaline::Contact)
      return unless (queue = @queue) && queue.is_a?(MockMessageQueue)

      queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        contact.phone_number,
        Array(Tourmaline::MessageEntity).new,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_contact(
            receiver,
            phone_number: contact.phone_number,
            first_name: contact.first_name,
            last_name: contact.last_name,
            vcard: contact.vcard,
            reply_to_message_id: reply,
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
