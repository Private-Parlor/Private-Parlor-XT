require "../spec_helper.cr"

module PrivateParlorXT
  class MockMessageQueue < MessageQueue
    def initialize
      @queue = Deque(QueuedMessage).new
      @queue_mutex = Mutex.new
    end

    # Creates a new `QueuedMessage` with a reply and pushes it to the back of the queue.
    def add_to_queue(
      cached_msid : Int64 | Array(Int64),
      sender_id : Int64 | Nil,
      receiver_ids : Array(Int64),
      reply_msids : Hash(Int64, Tourmaline::ReplyParameters),
      data : String,
      entities : Array(Tourmaline::MessageEntity)?,
      func : MessageProc
    ) : Nil
      unless entities
        entities = Array(Tourmaline::MessageEntity).new
      end

      @queue_mutex.synchronize do
        receiver_ids.each do |receiver_id|
          @queue.push(MockQueuedMessage.new(
            cached_msid,
            sender_id,
            receiver_id,
            reply_msids[receiver_id]?,
            func,
            data,
            entities,
          )
          )
        end
      end
    end

    # Creates a new `QueuedMessage` and pushes it to the back of the queue.
    # Useful for reply messages.
    def add_to_queue(
      receiver : Int64,
      receiver_message : Tourmaline::ReplyParameters?,
      data : String,
      entities : Array(Tourmaline::MessageEntity),
      func : MessageProc
    ) : Nil
      @queue_mutex.synchronize do
        @queue.push(
          MockQueuedMessage.new(
            nil,
            nil,
            receiver,
            receiver_message,
            func,
            data,
            entities,
          )
        )
      end
    end

    # Creates a new `QueuedMessage` and pushes it to the front of the queue.
    # Useful for reply messages.
    def add_to_queue_priority(
      receiver_id : Int64,
      reply : Tourmaline::ReplyParameters?,
      data : String,
      entities : Array(Tourmaline::MessageEntity),
      func : MessageProc
    ) : Nil
      @queue_mutex.synchronize do
        @queue.unshift(
          MockQueuedMessage.new(
            nil,
            nil,
            receiver_id,
            reply,
            func,
            data,
            entities,
          )
        )
      end
    end
  end
end
