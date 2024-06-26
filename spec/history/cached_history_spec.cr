require "../spec_helper.cr"

module PrivateParlorXT
  describe CachedHistory do
    describe "#initialize" do
      it "initializes empty message map" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.as(CachedHistory).message_map.should(eq({} of MessageID => CachedHistory::MessageGroup))
      end
    end

    describe "#new_message" do
      it "adds new message to message map" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        cached_message = history.as(CachedHistory).message_map[1]

        cached_message.sender.should(eq(100))
        cached_message.origin.should(eq(1))
        cached_message.receivers.should(eq({} of UserID => MessageID))
      rescue KeyError
        fail("Got KeyError when accessing message map")
      end
    end

    describe "#add_to_history" do
      it "adds receiver message to original message" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        receiver_msid = 2
        receiver_id = 101

        history.add_to_history(origin, receiver_msid, receiver_id)

        begin
          cached_message = history.as(CachedHistory).message_map[1]
        rescue KeyError
          fail("A message with the ID of '1' should be in the message map keys")
        end

        begin
          cached_message_reference = history.as(CachedHistory).message_map[2]
        rescue KeyError
          fail("A message with the ID of '2' should be in the message map keys")
        end

        cached_message.should(eq(cached_message_reference))

        receivers = cached_message_reference.receivers

        receivers.keys.should(contain(receiver_id))
        receivers.values.should(contain(receiver_msid))
      end
    end

    describe "#origin_message" do
      it "gets original message ID from receiver message ID" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        receiver_msid = 2
        receiver_id = 101

        history.add_to_history(origin, receiver_msid, receiver_id)

        history.origin_message(receiver_msid).should(eq(origin))
      end

      it "returns nil if receiver message ID has no original message" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        receiver_msid = 2

        history.origin_message(receiver_msid).should(be_nil)
      end
    end

    describe "#receivers" do
      it "gets all receiver messages IDs from a message group" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)
        history.add_to_history(origin, 3, 102)
        history.add_to_history(origin, 4, 103)

        expected = {
          100 => 1,
          101 => 2,
          102 => 3,
          103 => 4,
        } of Int64 => Int64

        history.receivers(1).should(eq(expected))
        history.receivers(2).should(eq(expected))
        history.receivers(3).should(eq(expected))
        history.receivers(4).should(eq(expected))
      end

      it "returns an empty hash if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.receivers(1).should(eq({} of Int64 => Int64))
      end
    end

    describe "#receiver_message" do
      it "gets receiver message ID for a given user" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)
        history.add_to_history(origin, 3, 102)
        history.add_to_history(origin, 4, 103)

        history.receiver_message(4, 101).should(eq(2))
        history.receiver_message(3, 103).should(eq(4))
        history.receiver_message(2, 100).should(eq(1))
      end

      it "returns nil if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.receiver_message(4, 101).should(be_nil)
      end
    end

    describe "#sender" do
      it "gets the sender ID of a message group from a receiver message ID" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)

        history.sender(2).should(eq(100))
      end

      it "returns nil if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.sender(2).should(be_nil)
      end
    end

    describe "#messages_from_user" do
      it "gets all recent message IDs sent by a given user" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.new_message(100, 1)
        history.new_message(100, 2)
        history.new_message(100, 3)
        history.new_message(100, 4)

        expected = [1, 2, 3, 4].to_set

        history.messages_from_user(100).should(eq(expected))
      end
    end

    describe "#add_rating" do
      it "adds rating to message" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)

        history.add_rating(2, 101).should(be_true)
        history.add_rating(2, 101).should(be_false)
      end
    end

    it "adds warning to message and gets warning" do
      history = CachedHistory.new(HISTORY_LIFESPAN)
      sender = 100
      origin = 1

      history.new_message(sender, origin)

      history.add_to_history(origin, 2, 101)

      history.warned?(2).should(be_false)
      history.add_warning(2)
      history.warned?(2).should(be_true)
    end

    describe "#purge_receivers" do
      it "returns messages to purge in descending order" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        generate_history(history)

        history.new_message(20000, 11)
        history.new_message(20000, 15)
        history.new_message(20000, 19)

        history.add_to_history(11, 12, 20000)
        history.add_to_history(11, 13, 80300)
        history.add_to_history(11, 14, 60200)

        history.add_to_history(15, 16, 20000)
        history.add_to_history(15, 17, 80300)
        history.add_to_history(15, 18, 60200)

        history.add_to_history(19, 20, 20000)
        history.add_to_history(19, 21, 80300)
        history.add_to_history(19, 22, 60200)

        purge_receivers = {
          20000 => [20, 16, 12],
          80300 => [21, 17, 13],
          60200 => [22, 18, 14],
        }

        history.purge_receivers(Set{11_i64, 15_i64, 19_i64}).should(eq(purge_receivers))
      end
    end

    describe "#delete_message_group" do
      it "deletes message group" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        # Add some messages with receivers that reference them
        history.new_message(100, 1)
        history.add_to_history(1, 2, 101)
        history.add_to_history(1, 3, 102)

        history.new_message(101, 4)
        history.add_to_history(4, 5, 100)
        history.add_to_history(4, 6, 102)

        history.new_message(102, 7)
        history.add_to_history(7, 8, 101)
        history.add_to_history(7, 9, 100)

        history.delete_message_group(2)
        history.delete_message_group(4)

        history.origin_message(3).should(be_nil)
        history.origin_message(5).should(be_nil)
      end
    end

    describe "#expire" do
      it "deletes old messages" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        # Add some messages with receivers that reference them
        history.new_message(100, 1)
        history.add_to_history(1, 2, 101)
        history.add_to_history(1, 3, 102)

        history.new_message(101, 4)
        history.add_to_history(4, 5, 100)
        history.add_to_history(4, 6, 102)

        history.new_message(102, 7)
        history.add_to_history(7, 8, 101)
        history.add_to_history(7, 9, 100)

        history.as(CachedHistory).message_map.size.should(eq(9))

        history.expire

        history.as(CachedHistory).message_map.size.should(eq(0))
      end
    end
  end
end
