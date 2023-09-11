require "tourmaline"

module PrivateParlorXT
  class Client < Tourmaline::Client
    @poller : Tourmaline::Poller?

    def poll : Nil
      @poller = Tourmaline::Poller.new(self).start
    end

    def stop : Nil
      return unless poller = @poller
      poller.stop
    end
  end
end

# Override some send functions to deal with an API bug with parse modes
module Tourmaline
  class Client
    module Api
      # Use this method to send text messages. On success, the sent Message is returned.
      def send_message(
        chat_id : Int32 | Int64 | String,
        text : String,
        message_thread_id : Int32 | Int64 | ::Nil = nil,
        parse_mode : Tourmaline::ParseMode? = default_parse_mode,
        entities : Array(Tourmaline::MessageEntity) | ::Nil = nil,
        disable_web_page_preview : Bool | ::Nil = nil,
        disable_notification : Bool | ::Nil = nil,
        protect_content : Bool | ::Nil = nil,
        reply_to_message_id : Int32 | Int64 | ::Nil = nil,
        allow_sending_without_reply : Bool | ::Nil = nil,
        reply_markup : Tourmaline::InlineKeyboardMarkup | Tourmaline::ReplyKeyboardMarkup | Tourmaline::ReplyKeyboardRemove | Tourmaline::ForceReply | ::Nil = nil
      )
        request(Tourmaline::Message, "sendMessage", {
          chat_id:                     chat_id,
          text:                        text,
          message_thread_id:           message_thread_id,
          parse_mode:                  parse_mode,
          entities:                    entities.try(&.to_json),
          disable_web_page_preview:    disable_web_page_preview,
          disable_notification:        disable_notification,
          protect_content:             protect_content,
          reply_to_message_id:         reply_to_message_id,
          allow_sending_without_reply: allow_sending_without_reply,
          reply_markup:                reply_markup.try(&.to_json),
        })
      end
    end
  end
end
