require "../constants.cr"
require "./queue.cr"
require "tourmaline"

module PrivateParlorXT
  class Relay
    @queue : MessageQueue = MessageQueue.new
    @client : Tourmaline::Client
    @log_channel : String

    private def initialize(@log_channel : String, @client : Tourmaline::Client)
    end

    def self.instance(log_channel : String, client : Tourmaline::Client)
      @@instance ||= new(log_channel, client)
    end

    def set_log_channel(channel_id : String)
      @log_channel = channel_id
    end

    # Relay a message to a single user. Used for system messages.
    def send_to_user(reply_message : MessageID?, user : Int64, text : String)
      @queue.add_to_queue_priority(
        user,
        reply_message,
        ->(receiver : UserID, reply : MessageID?) { @client.send_message(receiver, text, disable_web_page_preview: false, reply_to_message_id: reply) }
      )
    end

    def send_text(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, text : String, entities : Array(Tourmaline::MessageEntity))
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        ->(receiver : Int64, reply : Int64 | Nil) {
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

    def send_photo(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, photo : String, caption : String, entities : Array(Tourmaline::MessageEntity), spoiler : Bool?)
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        ->(receiver : Int64, reply : Int64 | Nil) {
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

    def send_animation(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, animation : String, caption : String, entities : Array(Tourmaline::MessageEntity), spoiler : Bool?)
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        ->(receiver : Int64, reply : Int64 | Nil) {
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

    def send_poll(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, poll : MessageID)
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        ->(receiver : Int64, reply : Int64 | Nil) {
          @client.forward_message(
            receiver,
            user.id,
            poll,
          )
        }
      )
    end

    def send_sticker(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, sticker_file : String)
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

    def send_venue(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, venue : Tourmaline::Venue)
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

    def send_location(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, location : Tourmaline::Location)
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

    def send_contact(origin : MessageID, user : User, receivers : Array(UserID), reply_msids : Hash(Int64, Int64)?, contact : Tourmaline::Contact)
      @queue.add_to_queue(
        origin,
        user.id,
        receivers,
        reply_msids,
        ->(receiver : UserID, reply : MessageID?) {
          @client.send_contact(
            receiver,
            phone_number:                contact.phone_number,
            first_name:                  contact.first_name,
            last_name:                   contact.last_name,
            vcard:                       contact.vcard,
            reply_to_message_id: reply,
          )
        }
      )
    end

    def log_output(text : String) : Nil
      Log.info { text }
      unless @log_channel.empty?
        @client.send_message(@log_channel, text)
      end
    end

    # Receives a `Message` from the `queue`, calls its proc, and adds the returned message id to the History
    #
    # This function should be invoked in a Fiber.
    def send_messages(database : Database, locale : Locale, history : History) : Bool?
      msg = @queue.get_message

      if msg.nil?
        return true
      end

      begin
        success = msg.function.call(msg.receiver, msg.reply_to)
      rescue Tourmaline::Error::BotBlocked | Tourmaline::Error::UserDeactivated
        if user = database.get_user(msg.receiver)
          user.set_left
          database.update_user(user)

          log = Format.substitute_message(locale.logs.force_leave, locale, {"id" => user.id.to_s})

          log_output(log)
        end

        @queue.reject_messsages do |queued_message|
          queued_message.receiver == msg.receiver
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
        history.add_to_history(msg.origin_msid.as(MessageID), success.message_id.to_i64, msg.receiver)
      when Array(Tourmaline::Message)
        sent_msids = success.map(&.message_id)

        sent_msids.zip(msg.origin_msid.as(Array(MessageID))) do |msid, origin_msid|
          history.add_to_history(origin_msid, msid.to_i64, msg.receiver)
        end
      end
    end
  end
end
