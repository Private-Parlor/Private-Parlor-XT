require "./queued_message.cr"

module PrivateParlorXT
  class MessageQueue
    getter queue : Deque(QueuedMessage)
    getter queue_mutex : Mutex
  
    def initialize
      @queue = Deque(QueuedMessage).new
      @queue_mutex = Mutex.new
    end
  
    def reject_messsages(&) : Nil
      @queue_mutex.synchronize do
        @queue.reject! do |msg|
          yield msg
        end
      end
    end
  
    # Creates a new `QueuedMessage` and pushes it to the back of the queue.
    def add_to_queue(cached_msid : Int64 | Array(Int64), sender_id : Int64 | Nil, receiver_ids : Array(Int64), reply_msid : Nil, func : MessageProc) : Nil
      @queue_mutex.synchronize do
        receiver_ids.each do |receiver_id|
          @queue.push(QueuedMessage.new(cached_msid, sender_id, receiver_id, nil, func))
        end
      end
    end
  
    # Creates a new `QueuedMessage` with a reply and pushes it to the back of the queue.
    def add_to_queue(cached_msid : Int64 | Array(Int64), sender_id : Int64 | Nil, receiver_ids : Array(Int64), reply_msids : Hash(Int64, Int64), func : MessageProc) : Nil
      @queue_mutex.synchronize do
        receiver_ids.each do |receiver_id|
          @queue.push(QueuedMessage.new(cached_msid, sender_id, receiver_id, reply_msids[receiver_id], func))
        end
      end
    end
  
    # Creates a new `QueuedMessage` and pushes it to the front of the queue.
    def add_to_queue_priority(receiver_id : Int64, reply_msid : Int64 | Nil, func : MessageProc) : Nil
      @queue_mutex.synchronize do
        @queue.unshift(QueuedMessage.new(nil, nil, receiver_id, reply_msid, func))
      end
    end
  
    def get_message : QueuedMessage?
      msg = nil
      @queue_mutex.synchronize do
        msg = @queue.shift?
      end
  
      msg
    end
  end
end