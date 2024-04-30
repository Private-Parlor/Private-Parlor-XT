require "../constants.cr"
require "./queue.cr"
require "tourmaline"

module PrivateParlorXT
  alias ReplyParameters = Tourmaline::ReplyParameters

  class RelayParameters
    getter original_message : MessageID
    getter sender : UserID
    getter receivers : Array(UserID)
    getter replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters
    getter text : String = ""
    getter entities : Array(Tourmaline::MessageEntity)? = nil
    getter link_preview_options : Tourmaline::LinkPreviewOptions? = nil
    getter media : String = ""
    getter spoiler : Bool? = nil

    def initialize(
      @original_message : MessageID,
      @sender : UserID,
      @receivers : Array(UserID),
      @replies : Hash(UserID, ReplyParameters) = {} of UserID => ReplyParameters,
      @text : String = "",
      @entities : Array(Tourmaline::MessageEntity)? = nil,
      @link_preview_options : Tourmaline::LinkPreviewOptions? = nil,
      @media : String = "",
      @spoiler : Bool? = nil
    )
    end
  end

  class Relay
    @client : PrivateParlorXT::Client
    @queue : MessageQueue = MessageQueue.new
    @log_channel : String

    def initialize(@log_channel : String, @client : Tourmaline::Client)
    end

    def set_log_channel(channel_id : String)
      @log_channel = channel_id
    end

    def start_polling
      @client.poll
    end

    def stop_polling
      @client.stop
    end

    # Relay a message to a single user. Used for system messages.
    def send_to_user(reply_message : ReplyParameters?, user : UserID, text : String, reply_markup : Tourmaline::InlineKeyboardMarkup? = nil)
      @queue.add_to_queue_priority(
        user,
        reply_message,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_message(
            receiver,
            text,
            link_preview_options: Tourmaline::LinkPreviewOptions.new,
            reply_parameters: reply,
            reply_markup: reply_markup
          )
        }
      )
    end

    # Relay a message to the log channel.
    def send_to_channel(reply_message : MessageID?, channel : String, text : String)
      return unless id = channel.to_i64?

      @queue.add_to_queue_priority(
        id,
        nil,
        ->(receiver : UserID, _reply : ReplyParameters?) {
          @client.send_message(
            receiver,
            text,
            parse_mode: nil
          )
        }
      )
    end

    def send_text(params : RelayParameters)
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_message(
            receiver,
            params.text,
            parse_mode: nil,
            entities: params.entities,
            link_preview_options: params.link_preview_options,
            reply_parameters: reply,
          )
        }
      )
    end

    def send_photo(params : RelayParameters)
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
        ->(receiver : UserID, reply : ReplyParameters?) {
          @client.send_voice(
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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

    def send_poll_copy(reply : MessageID, user : User, poll : Tourmaline::Poll)
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
        reply_parameters: ReplyParameters.new(reply),
      )
    end

    def send_forward(params : RelayParameters, message : MessageID)
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_messages,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
      @queue.add_to_queue(
        params.original_message,
        params.sender,
        params.receivers,
        params.replies,
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
        ReplyParameters.new(message),
        ->(receiver_id : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.delete_message(receiver_id, reply.message_id)
        }
      )
    end

    def purge_messages(receiver : UserID, messages : Array(MessageID))
      @queue.add_to_queue_priority(
        receiver,
        nil,
        ->(receiver_id : UserID, _reply : ReplyParameters?) {
          @client.delete_messages(receiver_id, messages)
        }
      )
    end

    def pin_message(user : UserID, message : MessageID)
      @queue.add_to_queue_priority(
        user,
        ReplyParameters.new(message),
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.pin_chat_message(receiver, reply.message_id)
        }
      )
    end

    def unpin_message(user : UserID, message : MessageID? = nil)
      if message
        message = ReplyParameters.new(message)
      else
        message = nil
      end

      @queue.add_to_queue_priority(
        user,
        message,
        ->(receiver : UserID, reply : ReplyParameters?) {
          if reply
            @client.unpin_chat_message(receiver, reply.message_id)
          else
            @client.unpin_chat_message(receiver, nil)
          end
        }
      )
    end

    def edit_message_media(user : UserID, media : Tourmaline::InputMedia, message : MessageID)
      @queue.add_to_queue_priority(
        user,
        ReplyParameters.new(message),
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.edit_message_media(media, receiver, reply.message_id)
          # We don't care about the result, so return a boolean
          # to satisfy type requirements
          true
        }
      )
    end

    def edit_message_text(user : UserID, text : String, markup : Tourmaline::InlineKeyboardMarkup?, message : MessageID)
      @queue.add_to_queue_priority(
        user,
        ReplyParameters.new(message),
        ->(receiver : UserID, reply : ReplyParameters?) {
          return false unless reply
          @client.edit_message_text(text, receiver, reply.message_id, reply_markup: markup)
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

    # Takes a message from the queue and sends it.
    #
    # Returns true if queue is empty
    def send_message(services : Services) : Bool?
      return true unless msg = @queue.get_message

      return unless success = relay_message(msg, services)

      cache_message(success, msg, services)
    end

    # Calls the proc associated with the given message.
    #
    # Returns a `Tourmaline::Message` when sending messages that are not albums
    # Returns an array of `Tourmaline::Message` for sent albums
    # Returns nil on sending a system message, Telegram giving us a boolean,
    # or encountering an error
    def relay_message(message : QueuedMessage, services : Services) : Tourmaline::Message | Array(Tourmaline::Message) | Nil
      success = message.function.call(message.receiver, message.reply_to)

      return unless message.origin_msid # System messages have this set to nil
      return if success.is_a?(Bool)

      success
    rescue Tourmaline::Error::BotBlocked | Tourmaline::Error::UserDeactivated
      if user = services.database.get_user(message.receiver)
        user.set_left
        services.database.update_user(user)

        log = Format.substitute_message(services.logs.force_leave, {"id" => user.id.to_s, "name" => user.get_formatted_name})

        log_output(log)
      end

      reject_inactive_user_messages(message.receiver)
    rescue ex : Tourmaline::Error::ChatNotFound
      if message.origin_msid
        Log.error(exception: ex) { "Error occured when relaying message." }
      end
    rescue ex : Tourmaline::Error::RetryAfter
      Log.error(exception: ex) { "Error occured when relaying message." }

      sleep(ex.seconds.seconds)

      relay_message(message, services)
    rescue ex
      Log.error(exception: ex) { "Error occured when relaying message." }
    end

    # Caches data from the message returned from Telegram in the message `History`
    def cache_message(success : Tourmaline::Message | Array(Tourmaline::Message), message : QueuedMessage, services : Services) : Nil
      case success
      when Tourmaline::Message
        services.history.add_to_history(message.origin_msid.as(MessageID), success.message_id.to_i64, message.receiver)
      when Array(Tourmaline::Message)
        sent_msids = success.map(&.message_id)

        sent_msids.zip(message.origin_msid.as(Array(MessageID))) do |msid, origin_msid|
          services.history.add_to_history(origin_msid, msid.to_i64, message.receiver)
        end
      end
    end
  end
end
