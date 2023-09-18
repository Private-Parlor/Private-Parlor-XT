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

    describe "#get_origin_message" do
      it "gets original message ID from receiver message ID" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        receiver_msid = 2
        receiver_id = 101

        history.add_to_history(origin, receiver_msid, receiver_id)

        history.get_origin_message(receiver_msid).should(eq(origin))
      end

      it "returns nil if receiver message ID has no original message" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        receiver_msid = 2

        history.get_origin_message(receiver_msid).should(be_nil)
      end
    end

    describe "#get_all_receivers" do
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

        history.get_all_receivers(1).should(eq(expected))
        history.get_all_receivers(2).should(eq(expected))
        history.get_all_receivers(3).should(eq(expected))
        history.get_all_receivers(4).should(eq(expected))
      end

      it "returns an empty hash if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.get_all_receivers(1).should(eq({} of Int64 => Int64))
      end
    end

    describe "#get_receiver_message" do
      it "gets receiver message ID for a given user" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)
        history.add_to_history(origin, 3, 102)
        history.add_to_history(origin, 4, 103)

        history.get_receiver_message(4, 101).should(eq(2))
        history.get_receiver_message(3, 103).should(eq(4))
        history.get_receiver_message(2, 100).should(eq(1))
      end

      it "returns nil if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.get_receiver_message(4, 101).should(be_nil)
      end
    end

    describe "#get_sender" do
      it "gets the sender ID of a message group from a receiver message ID" do
        history = CachedHistory.new(HISTORY_LIFESPAN)
        sender = 100
        origin = 1

        history.new_message(sender, origin)

        history.add_to_history(origin, 2, 101)

        history.get_sender(2).should(eq(100))
      end

      it "returns nil if original message does not exist" do
        history = CachedHistory.new(HISTORY_LIFESPAN)

        history.get_sender(2).should(be_nil)
      end
    end

    it "gets all message IDs sent by a given user" do
      history = CachedHistory.new(HISTORY_LIFESPAN)

      history.new_message(100, 1)
      history.new_message(100, 2)
      history.new_message(100, 3)
      history.new_message(100, 4)

      expected = [1, 2, 3, 4].to_set

      history.get_messages_from_user(100).should(eq(expected))
    end

    it "adds rating to message" do
      history = CachedHistory.new(HISTORY_LIFESPAN)
      sender = 100
      origin = 1

      history.new_message(sender, origin)

      history.add_to_history(origin, 2, 101)

      history.add_rating(2, 101).should(be_true)
      history.add_rating(2, 101).should(be_false)
    end

    it "deletes old messages" do
      history = CachedHistory.new(Time::Span.zero)

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
