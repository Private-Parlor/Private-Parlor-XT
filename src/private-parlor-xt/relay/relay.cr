require "../constants.cr"
require "./queue.cr"
require "tourmaline"

module PrivateParlorXT
  class Relay
    @client : PrivateParlorXT::Client
    @queue : MessageQueue = MessageQueue.new
    @log_channel : String

    def initialize(@log_channel : String, @client : Tourmaline::Client)
    end

    def set_log_channel(channel_id : String)
      @log_channel = channel_id
    end

    def get_client_user : Tourmaline::User
      @client.bot
    end

    def start_polling
      @client.poll
    end

    def stop_polling
      @client.stop
    end

    # Relay a message to a single user. Used for system messages.
    def send_to_user(reply_message : MessageID?, user : UserID, text : String)
      @queue.add_to_queue_priority(
        user,
        reply_message,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_message(
            receiver,
            text,
            disable_web_page_preview: false,
            reply_to_message_id: reply
          )
        }
      )
    end

    # Relay a message to a single user. Used for system messages that need not be sent immediately
    def delay_send_to_user(reply_message : MessageID?, user : UserID, text : String)
      @queue.add_to_queue(
        user,
        reply_message,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_message(
            receiver,
            text,
            disable_web_page_preview: false,
            reply_to_message_id: reply
          )
        }
      )
    end

    # Relay a message to the log channel.
    def send_to_channel(reply_message : MessageID?, channel : String, text : String)
      return unless id = channel.to_i64?

      @queue.add_to_queue(
        id,
        nil,
        ->(receiver : UserID, _reply : MessageID?) {
          @client.send_message(
            id,
            text,
            parse_mode: nil,
            disable_web_page_preview: false,
          )
        }
      )
    end

    def send_text(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(UserID, MessageID)?, text : String, entities : Array(Tourmaline::MessageEntity))
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @client.send_poll(
        user.id,
        question: poll.question,
        options: poll.options.map(&.text),
        is_anonymous: true,
        type: poll.type,
        allows_multiple_answers: poll.allows_multiple_answers?,
        correct_option_id: poll.correct_option_id,
        explanation: poll.explanation,
        explanation_entities: poll.explanation_entities,
        open_period: poll.open_period,
        reply_to_message_id: reply,
      )
    end

    def send_forward(origin : MessageID, user : User, receivers : Array(UserID), message : MessageID)
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        nil,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origins,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
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

    def reject_blacklisted_messages(user : UserID)
      @queue.reject_messages do |msg|
        msg.receiver == user || msg.sender == user
      end
    end

    def reject_inactive_user_messages(user : UserID)
      @queue.reject_messages do |msg|
        msg.receiver == user
      end
    end

    def delete_message(receiver : UserID, message : MessageID)
      @queue.add_to_queue_priority(
        receiver,
        message,
        ->(receiver_id : UserID, message_id : MessageID?) {
          return false unless message_id
          @client.delete_message(receiver_id, message_id)
        }
      )
    end

    def remove_message(receiver : UserID, message : MessageID)
      @queue.add_to_queue(
        receiver,
        message,
        ->(receiver_id : UserID, message_id : MessageID?) {
          return false unless message_id
          @client.delete_message(receiver_id, message_id)
        }
      )
    end

    def pin_message(user : UserID, message : MessageID)
      @queue.add_to_queue(
        user,
        message,
        ->(receiver : UserID, message_id : MessageID?) {
          return false unless message_id
          @client.pin_chat_message(receiver, message_id)
        }
      )
    end

    def unpin_message(user : UserID, message : MessageID? = nil)
      @queue.add_to_queue(
        user,
        message,
        ->(receiver : UserID, message_id : MessageID?) {
          @client.unpin_chat_message(receiver, message_id)
        }
      )
    end

    def edit_message_media(user : UserID, media : Tourmaline::InputMedia, message : MessageID)
      @queue.add_to_queue(
        user,
        nil,
        ->(receiver : UserID, message_id : MessageID?) {
          @client.edit_message_media(media, receiver, message_id)
          # We don't care about the result, so return a boolean
          # to satisfy type requirements
          true
        }
      )
    end

    def log_output(text : String) : Nil
      Log.info { text }
      unless @log_channel.empty?
        send_to_channel(nil, @log_channel, text)
      end
    end

    # Receives a `Message` from the `queue`, calls its proc, and adds the returned message id to the History
    #
    # This function should be invoked in a Fiber.
    def send_messages(services : Services) : Bool?
      msg = @queue.get_message

      if msg.nil?
        return true
      end

      begin
        success = msg.function.call(msg.receiver, msg.reply_to)
      rescue Tourmaline::Error::BotBlocked | Tourmaline::Error::UserDeactivated
        if user = services.database.get_user(msg.receiver)
          user.set_left
          services.database.update_user(user)

          log = Format.substitute_message(services.logs.force_leave, {"id" => user.id.to_s})

          log_output(log)
        end

        @queue.reject_messages do |queued_message|
          queued_message.receiver == msg.receiver
        end
        return
      rescue ex : Tourmaline::Error::ChatNotFound
        if msg.origin_msid
          Log.error(exception: ex) { "Error occured when relaying message." }
        end
        return
      rescue ex
        return Log.error(exception: ex) { "Error occured when relaying message." }
      end

      unless msg.origin_msid
        return
      end

      case success
      when Tourmaline::Message
        services.history.add_to_history(msg.origin_msid.as(MessageID), success.message_id.to_i64, msg.receiver)
      when Array(Tourmaline::Message)
        sent_msids = success.map(&.message_id)

        sent_msids.zip(msg.origin_msid.as(Array(MessageID))) do |msid, origin_msid|
          services.history.add_to_history(origin_msid, msid.to_i64, msg.receiver)
        end
      end
    end
  end
end
