require "../spec_helper.cr"

module PrivateParlorXT
  describe MessageQueue do
    proc = ->(_receiver : UserID, _message : MessageID?) { true }

    describe "#reject_messages" do
      it "deletes messages in queue according to given conditions" do
        message_queue = MessageQueue.new

        message_queue.add_to_queue(100_i64, 1_i64, proc)
        message_queue.add_to_queue(101_i64, 2_i64, proc)
        message_queue.add_to_queue(102_i64, 3_i64, proc)

        message_queue.queue.size.should(eq(3))

        message_queue.reject_messages do |msg|
          next unless reply = msg.reply_to

          reply < 3
        end

        message_queue.queue.size.should(eq(1))

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message.receiver.should(eq(102))
        message.reply_to.should(eq(3))
      end
    end

    describe "#add_to_queue" do
      it "adds cached message to the end of the queue" do
        message_queue = MessageQueue.new

        message_queue.queue.size.should(eq(0))

        message_queue.add_to_queue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          nil,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        unless message_one = message_queue.get_message
          fail("Message should not be nil")
        end

        message_one.origin_msid.should(eq(100))
        message_one.sender.should(eq(9000))
        message_one.receiver.should(eq(1500))
        message_one.reply_to.should(be_nil)

        message_queue.queue.size.should(eq(2))

        unless message_two = message_queue.get_message
          fail("Message should not be nil")
        end

        message_two.origin_msid.should(eq(100))
        message_two.sender.should(eq(9000))
        message_two.receiver.should(eq(1700))
        message_two.reply_to.should(be_nil)

        message_queue.queue.size.should(eq(1))

        unless message_three = message_queue.get_message
          fail("Message should not be nil")
        end

        message_three.origin_msid.should(eq(100))
        message_three.sender.should(eq(9000))
        message_three.receiver.should(eq(1900))
        message_three.reply_to.should(be_nil)
      end

      it "addes cached message with reply to the end of the queue" do
        message_queue = MessageQueue.new

        message_queue.queue.size.should(eq(0))

        replies = {
          1500_i64 => 97_i64,
          1700_i64 => 98_i64,
        }

        message_queue.add_to_queue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          replies,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        unless message_one = message_queue.get_message
          fail("Message should not be nil")
        end

        message_one.origin_msid.should(eq(100))
        message_one.sender.should(eq(9000))
        message_one.receiver.should(eq(1500))
        message_one.reply_to.should(eq(97))

        message_queue.queue.size.should(eq(2))

        unless message_two = message_queue.get_message
          fail("Message should not be nil")
        end

        message_two.origin_msid.should(eq(100))
        message_two.sender.should(eq(9000))
        message_two.receiver.should(eq(1700))
        message_two.reply_to.should(eq(98))

        message_queue.queue.size.should(eq(1))

        unless message_three = message_queue.get_message
          fail("Message should not be nil")
        end

        message_three.origin_msid.should(eq(100))
        message_three.sender.should(eq(9000))
        message_three.receiver.should(eq(1900))
        message_three.reply_to.should(be_nil)
      end

      it "adds system message to the end of the queue" do
        message_queue = MessageQueue.new

        message_queue.add_to_queue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          nil,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        message_queue.add_to_queue(9000, 100, proc)

        message_queue.queue.size.should(eq(4))

        message_queue.get_message
        message_queue.get_message
        message_queue.get_message

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message.origin_msid.should(be_nil)
        message.sender.should(be_nil)
        message.receiver.should(eq(9000))
        message.reply_to.should(eq(100))
      end
    end

    describe "#add_to_queue_priority" do
      it "adds QueuedMessage to the front of the queue" do
        message_queue = MessageQueue.new

        message_queue.add_to_queue(
          100_i64,
          9000_i64,
          [1500_i64, 1700_i64, 1900_i64],
          nil,
          proc,
        )

        message_queue.queue.size.should(eq(3))

        message_queue.add_to_queue_priority(9000, 100, proc)

        message_queue.queue.size.should(eq(4))

        unless message = message_queue.get_message
          fail("Message should not be nil")
        end

        message.origin_msid.should(be_nil)
        message.sender.should(be_nil)
        message.receiver.should(eq(9000))
        message.reply_to.should(eq(100))
      end
    end

    describe "#get_message" do
      it "returns first QueuedMessage in queue" do
        message_queue = MessageQueue.new

        message_queue.add_to_queue(100_i64, 1_i64, proc)
        message_queue.add_to_queue(101_i64, 2_i64, proc)
        message_queue.add_to_queue(102_i64, 3_i64, proc)

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
