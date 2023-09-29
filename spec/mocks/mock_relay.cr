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
