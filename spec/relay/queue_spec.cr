require "../spec_helper.cr"

module PrivateParlorXT
  describe MessageQueue do
    proc = ->(_receiver : UserID, _message : ReplyParameters?) { true }

    describe "#reject_messages" do
      it "deletes messages in queue according to given conditions" do
        message_queue = MessageQueue.new

        message_queue.enqueue_priority(100_i64, ReplyParameters.new(1_i64), proc)
        message_queue.enqueue_priority(101_i64, ReplyParameters.new(2_i64), proc)
        message_queue.enqueue_priority(102_i64, ReplyParameters.new(3_i64), proc)

        message_queue.queue.size.should(eq(3))

        message_queue.reject_messages do |msg|
          next unless reply_to_message = msg.reply

          reply_to_message.message_id < 3
        end

        message_queue.queue.size.should(eq(1))

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message.receiver.should(eq(102))
        unless reply_to_message = message.reply
          fail("Message reply should not be nil")
        end
        reply_to_message.message_id.should(eq(3))
      end
    end

    describe "#enqueue" do
      it "adds cached message to the end of the queue" do
        message_queue = MessageQueue.new

        message_queue.queue.size.should(eq(0))

        message_queue.enqueue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          Hash(UserID, ReplyParameters).new,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        unless message_one = message_queue.get_message
          fail("Message should not be nil")
        end

        message_one.origin.should(eq(100))
        message_one.sender.should(eq(9000))
        message_one.receiver.should(eq(1500))
        message_one.reply.should(be_nil)

        message_queue.queue.size.should(eq(2))

        unless message_two = message_queue.get_message
          fail("Message should not be nil")
        end

        message_two.origin.should(eq(100))
        message_two.sender.should(eq(9000))
        message_two.receiver.should(eq(1700))
        message_two.reply.should(be_nil)

        message_queue.queue.size.should(eq(1))

        unless message_three = message_queue.get_message
          fail("Message should not be nil")
        end

        message_three.origin.should(eq(100))
        message_three.sender.should(eq(9000))
        message_three.receiver.should(eq(1900))
        message_three.reply.should(be_nil)
      end

      it "adds cached message with reply to the end of the queue" do
        message_queue = MessageQueue.new

        message_queue.queue.size.should(eq(0))

        replies = {
          1500_i64 => ReplyParameters.new(97_i64),
          1700_i64 => ReplyParameters.new(98_i64),
        }

        message_queue.enqueue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          replies,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        unless message_one = message_queue.get_message
          fail("Message_one should not be nil")
        end

        message_one.origin.should(eq(100))
        message_one.sender.should(eq(9000))
        message_one.receiver.should(eq(1500))
        unless reply_to_message = message_one.reply
          fail("Message_one reply should not be nil")
        end
        reply_to_message.message_id.should(eq(97))

        message_queue.queue.size.should(eq(2))

        unless message_two = message_queue.get_message
          fail("Message_two should not be nil")
        end

        message_two.origin.should(eq(100))
        message_two.sender.should(eq(9000))
        message_two.receiver.should(eq(1700))
        unless reply_to_message = message_two.reply
          fail("Message_two reply should not be nil")
        end
        reply_to_message.message_id.should(eq(98))

        message_queue.queue.size.should(eq(1))

        unless message_three = message_queue.get_message
          fail("Message_three should not be nil")
        end

        message_three.origin.should(eq(100))
        message_three.sender.should(eq(9000))
        message_three.receiver.should(eq(1900))
        message_three.reply.should(be_nil)
      end
    end

    describe "#enqueue_priority" do
      it "adds QueuedMessage to the front of the queue" do
        message_queue = MessageQueue.new

        message_queue.enqueue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          Hash(UserID, ReplyParameters).new,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        message_queue.enqueue_priority(9000, ReplyParameters.new(100), proc)

        message_queue.queue.size.should(eq(4))

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message.origin.should(be_nil)
        message.sender.should(be_nil)
        message.receiver.should(eq(9000))
        unless reply_to_message = message.reply
          fail("Message reply should not be nil")
        end
        reply_to_message.message_id.should(eq(100))
      end
    end

    describe "#get_message" do
      it "returns first QueuedMessage in queue" do
        message_queue = MessageQueue.new

        message_queue.enqueue(
          200_i64,
          nil,
          [100_i64],
          {100_i64 => ReplyParameters.new(1_i64)},
          proc
        )

        message_queue.enqueue(
          201_i64,
          nil,
          [101_i64],
          {101_i64 => ReplyParameters.new(2_i64)},
          proc
        )

        message_queue.enqueue(
          202_i64,
          nil,
          [102_i64],
          {102_i64 => ReplyParameters.new(3_i64)},
          proc
        )

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message_queue.queue.size.should(eq(2))

        message.receiver.should(eq(100))
      end

      it "returns nil if queue is empty" do
        message_queue = MessageQueue.new

        message_queue.get_message.should(be_nil)
      end
    end
  end
end
