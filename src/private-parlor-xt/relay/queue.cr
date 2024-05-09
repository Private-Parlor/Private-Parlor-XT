require "./queued_message.cr"

module PrivateParlorXT
  
  # A container for messages ready to be sent to Telegram
  class MessageQueue
    # A double-ended queue of `QueuedMessage`; enqueued user messages are sent to the back of the queue, while system messages are sent to the front. 
    getter queue : Deque(QueuedMessage)

    # Provides mutually exclusion for elements in the queue. Assume that it is necessary when interacting with the queue.
    getter queue_mutex : Mutex

    def initialize
      @queue = Deque(QueuedMessage).new
      @queue_mutex = Mutex.new
    end

    # Removes messsages from queue based on if the given block is truthy
    def reject_messages(&) : Nil
      @queue_mutex.synchronize do
        @queue.reject! do |msg|
          yield msg
        end
      end
    end

    # Creates a new `QueuedMessage` and pushes it to the back of the queue.
    def add_to_queue(cached_msid : Int64 | Array(Int64), sender_id : Int64 | Nil, receiver_ids : Array(Int64), reply_msids : Hash(Int64, ReplyParameters), func : MessageProc) : Nil
      @queue_mutex.synchronize do
        receiver_ids.each do |receiver_id|
          @queue.push(QueuedMessage.new(cached_msid, sender_id, receiver_id, reply_msids[receiver_id]?, func))
        end
      end
    end

    # Creates a new `QueuedMessage` and pushes it to the front of the queue.
    # Useful for reply messages.
    def add_to_queue_priority(receiver_id : Int64, reply : ReplyParameters?, func : MessageProc) : Nil
      @queue_mutex.synchronize do
        @queue.unshift(QueuedMessage.new(nil, nil, receiver_id, reply, func))
      end
    end

    # Returns the first `QueuedMessage` in the `queue` if it is available
    # 
    # Returns `nil` if there is no `QueuedMessage` in the `queue`
    def get_message : QueuedMessage?
      msg = nil
      @queue_mutex.synchronize do
        msg = @queue.shift?
      end

      msg
    end
  end
end
