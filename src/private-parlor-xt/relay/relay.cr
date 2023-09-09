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

    def send_text(reply : MessageID?, user : User, origin : MessageID, text : String, locale : Locale, history : History, database : Database)
      if reply
        reply_msids = history.get_all_receivers(reply)

        if reply_msids.empty?
          send_to_user(origin, user.id, locale.replies.not_in_cache)
          history.delete_message_group(origin)
          return
        end
      end

      @queue.add_to_queue(
        origin,
        user.id,
        user.debug_enabled ? database.get_active_users : database.get_active_users(user.id),
        reply_msids,
        ->(receiver : Int64, reply : Int64 | Nil) {
          @client.send_message(receiver, text, disable_web_page_preview: false, reply_to_message_id: reply)
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
