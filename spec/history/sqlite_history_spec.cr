require "../spec_helper.cr"

module PrivateParlorXT
  def self.sqlite_history_messages(connection : DB::Database) : Nil
    # Add message groups
    connection.exec("INSERT INTO message_groups VALUES (1,80300,'2023-01-02 06:00:00.000',0)")
    connection.exec("INSERT INTO message_groups VALUES (4,20000,'2023-01-02 06:00:00.000',0)")
    connection.exec("INSERT INTO message_groups VALUES (8,60200,'2023-01-02 06:00:00.000',1)")

    # Add receivers
    connection.exec("INSERT INTO receivers VALUES (2,60200,1)")
    connection.exec("INSERT INTO receivers VALUES (3,20000,1)")

    connection.exec("INSERT INTO receivers VALUES (5,20000,4)")
    connection.exec("INSERT INTO receivers VALUES (6,80300,4)")
    connection.exec("INSERT INTO receivers VALUES (7,60200,4)")

    connection.exec("INSERT INTO receivers VALUES (9,20000,8)")
    connection.exec("INSERT INTO receivers VALUES (10,80300,8)")

    # Add karma
    connection.exec("INSERT INTO karma VALUES (2,60200)")
  end

  describe SQLiteHistory, tags: "database" do
    describe "#new_message" do
      it "adds new message to database" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        sender = 100
        origin = 50

        db.new_message(sender, origin)

        db.origin_message(50).should(eq(50))
        db.sender(50).should(eq(100))
      end
    end

    describe "#add_to_history" do
      it "adds receiver message to database" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        sender = 100
        origin = 50

        db.new_message(sender, origin)

        receiver_msid = 51
        receiver_id = 101

        db.add_to_history(origin, receiver_msid, receiver_id)

        receivers = db.receivers(receiver_msid)

        begin
          receivers[101].should(eq(51))
        rescue KeyError
          fail("A message with the ID of '51' should be in the receivers table")
        end
      end
    end

    describe "#origin_message" do
      it "gets original message ID from receiver message ID" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        msid = db.origin_message(9)

        unless msid
          fail("Origin message ID should not be nil")
        end

        msid.should(eq(8))
      end

      it "gets original message ID from debug receiver message ID" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        msid = db.origin_message(5)

        unless msid
          fail("Origin message ID should not be nil")
        end

        msid.should(eq(4))
      end

      it "returns nil if receiver message ID has no original message" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.origin_message(12345).should(be_nil)
      end
    end

    describe "#receivers" do
      it "gets all receiver messages IDs from a message group" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        expected = {
          20000 => 5,
          80300 => 6,
          60200 => 7,
        } of Int64 => Int64

        db.receivers(5).should(eq(expected))
        db.receivers(6).should(eq(expected))
        db.receivers(7).should(eq(expected))
      end

      it "returns an empty hash if original message does not exist" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.receivers(12345).should(eq({} of Int64 => Int64))
      end
    end

    describe "#receiver_message" do
      it "gets receiver message ID for a given user" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.receiver_message(7, 80300).should(eq(6))
        db.receiver_message(6, 20000).should(eq(5))
        db.receiver_message(5, 60200).should(eq(7))
      end

      it "returns nil if original message does not exist" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.receiver_message(50, 100).should(be_nil)
      end
    end

    describe "#sender" do
      it "gets the sender ID of a message group from a receiver message ID" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.sender(10).should(eq(60200))
      end

      it "returns nil if original message does not exist" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.sender(50).should(be_nil)
      end
    end

    describe "#messages_from_user" do
      it "gets all recent message IDs sent by a given user" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.new_message(80300, 11)
        db.new_message(80300, 15)
        db.new_message(80300, 19)

        old_included = [1, 11, 15, 19].to_set
        expected = [11, 15, 19].to_set

        db.messages_from_user(80300).should_not(eq(old_included))
        db.messages_from_user(80300).should(eq(expected))
      end
    end

    describe "#add_rating" do
      it "adds rating to message" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.add_rating(3, 20000).should(be_true)
        db.add_rating(2, 60200).should(be_false)
      end
    end

    it "adds warning to message and gets warning" do
      connection = DB.open("sqlite3://%3Amemory%3A")
      db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

      sqlite_history_messages(connection)

      db.warned?(2).should(be_false)
      db.add_warning(2)
      db.warned?(2).should(be_true)
    end

    describe "#purge_receivers" do
      it "returns messages to purge in descending order" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.new_message(20000, 11)
        db.new_message(20000, 15)
        db.new_message(20000, 19)

        db.add_to_history(11, 12, 20000)
        db.add_to_history(11, 13, 80300)
        db.add_to_history(11, 14, 60200)

        db.add_to_history(15, 16, 20000)
        db.add_to_history(15, 17, 80300)
        db.add_to_history(15, 18, 60200)

        db.add_to_history(19, 20, 20000)
        db.add_to_history(19, 21, 80300)
        db.add_to_history(19, 22, 60200)

        purge_receivers = {
          20000 => [20, 16, 12],
          80300 => [21, 17, 13],
          60200 => [22, 18, 14],
        }

        db.purge_receivers(Set{11_i64, 15_i64, 19_i64}).should(eq(purge_receivers))
      end
    end

    describe "#delete_message_group" do
      it "deletes message group" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.delete_message_group(2)
        db.delete_message_group(4)

        db.origin_message(3).should(be_nil)
        db.origin_message(5).should(be_nil)
      end
    end

    describe "#expire" do
      it "deletes old messages" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteHistory.new(HISTORY_LIFESPAN, connection)

        sqlite_history_messages(connection)

        db.expire

        db.messages_from_user(80300).should(be_empty)
        db.messages_from_user(20000).should(be_empty)
        db.messages_from_user(60200).should(be_empty)
      end
    end
  end
end
