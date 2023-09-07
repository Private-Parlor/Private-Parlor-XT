require "../spec_helper.cr"

module PrivateParlorXT
  describe SQLiteHistory, tags: "database" do

    # TODO: Ideally these tests would do something smarter than re-creating 
    # the same database over and over
    around_each do |example|
      create_sqlite_database
      example.run
      delete_sqlite_database
    end

    describe "#new_message" do
      it "adds new message to database" do
        db = instantiate_sqlite_history
        sender = 100
        origin = 50

        db.new_message(sender, origin)

        db.get_origin_message(50).should(eq(50))
        db.get_sender(50).should(eq(100))

        db.close
      end
    end

    it "adds receiver message to database" do
      db = instantiate_sqlite_history
      sender = 100
      origin = 50

      db.new_message(sender, origin)

      receiver_msid = 51
      receiver_id = 101

      db.add_to_history(origin, receiver_msid, receiver_id)

      receivers = db.get_all_receivers(receiver_msid)

      begin
        receivers[101].should(eq(51))
      rescue KeyError
        fail("A message with the ID of \'51\' should be in the receivers table")
      end

      db.close
    end

    describe "#get_origin_message" do
      it "gets original message ID from receiver message ID" do
        db = instantiate_sqlite_history

        msid = db.get_origin_message(9)

        unless msid
          fail("Origin message ID should not be nil")
        end
        
        msid.should(eq(8))

        db.close  
      end

      it "gets original message ID from debug receiver message ID" do
        db = instantiate_sqlite_history

        msid = db.get_origin_message(5)

        unless msid
          fail("Origin message ID should not be nil")
        end

        msid.should(eq(4))

        db.close
      end

      it "returns nil if receiver message ID has no original message" do
        db = instantiate_sqlite_history

        db.get_origin_message(12345).should(be_nil)

        db.close
      end
    end

    describe "#get_all_receivers" do
      it "gets all receiver messages IDs from a message group" do
        db = instantiate_sqlite_history

        expected = {
          20000 => 5,
          80300 => 6,
          60200 => 7,
        } of Int64 => Int64

        db.get_all_receivers(5).should(eq(expected))
        db.get_all_receivers(6).should(eq(expected))
        db.get_all_receivers(7).should(eq(expected))

        db.close
      end

      it "returns an empty hash if original message does not exist" do
        db = instantiate_sqlite_history

        db.get_all_receivers(12345).should(eq({} of Int64 => Int64))

        db.close
      end
    end

    describe "#get_receiver_message" do
      it "gets receiver message ID for a given user" do
        db = instantiate_sqlite_history

        db.get_receiver_message(7, 80300).should(eq(6))
        db.get_receiver_message(6, 20000).should(eq(5))
        db.get_receiver_message(5, 60200).should(eq(7))

        db.close
      end

      it "returns nil if original message does not exist" do
        db = instantiate_sqlite_history

        db.get_receiver_message(50, 100).should(be_nil)

        db.close
      end
    end

    describe "#get_sender" do
      it "gets the sender ID of a message group from a receiver message ID" do
        db = instantiate_sqlite_history

        db.get_sender(10).should(eq(60200))

        db.close
      end

      it "returns nil if original message does not exist" do
        db = instantiate_sqlite_history

        db.get_sender(50).should(be_nil)

        db.close
      end
    end

    it "gets all message IDs sent by a given user" do 
      db = instantiate_sqlite_history

      db.new_message(80300, 11)

      expected = [1, 11].to_set

      db.get_messages_from_user(80300).should(eq(expected))

      db.close
    end

    it "deletes old messages" do
      db = instantiate_sqlite_history

      db.expire

      db.get_messages_from_user(80300).should(be_empty)
      db.get_messages_from_user(20000).should(be_empty)
      db.get_messages_from_user(60200).should(be_empty)

      db.close
    end
  end
end