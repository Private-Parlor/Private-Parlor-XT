require "../spec_helper.cr"

module PrivateParlorXT
  def self.generate_message_stats(connection : DB::Database) : Nil
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now'), '0', '1', '3', '0', '0', '0', '4', '5', '0', '0', '1', '0', '0', '4', '0', '0', '2', '0', '0', '22');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-1 day'), '0', '1', '2', '2', '0', '4', '0', '0', '0', '0', '3', '0', '0', '9', '0', '3', '0', '0', '5', '24');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-2 days'), '5', '3', '0', '0', '3', '0', '0', '6', '0', '0', '1', '0', '0', '0', '8', '0', '3', '0', '0', '31');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-6 days'), '4', '3', '0', '0', '4', '0', '8', '6', '0', '0', '0', '4', '0', '0', '3', '0', '3', '6', '0', '41');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-7 days'), '5', '2', '0', '3', '7', '0', '7', '0', '0', '8', '0', '3', '0', '0', '5', '0', '3', '7', '7', '50');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-8 days'), '5', '7', '8', '1', '0', '2', '8', '0', '0', '8', '0', '5', '0', '0', '5', '0', '6', '7', '0', '62');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-9 days'), '1', '2', '0', '5', '1', '0', '7', '0', '0', '8', '0', '3', '0', '0', '4', '0', '8', '0', '8', '39');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-10 days'), '0', '6', '0', '6', '8', '0', '6', '0', '0', '3', '0', '3', '0', '0', '5', '0', '3', '1', '0', '41');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-1 month'), '0', '2', '0', '6', '3', '0', '8', '0', '5', '3', '0', '3', '0', '0', '5', '0', '3', '1', '3', '39');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-1 month', '-1 day'), '0', '1', '0', '6', '4', '4', '8', '0', '0', '3', '0', '3', '0', '8', '5', '0', '3', '1', '0', '41');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-1 month', '-2 days'), '1', '2', '0', '6', '1', '8', '3', '0', '0', '3', '0', '3', '6', '0', '5', '0', '3', '1', '0', '42');
    ")
    connection.exec("INSERT INTO message_stats 
      VALUES (date('now', '-1 month', '-3 days'), '7', '2', '0', '6', '2', '9', '7', '0', '0', '3', '0', '3', '0', '4', '5', '0', '3', '1', '0', '52');
    ")
  end

  def self.generate_user_stats(connection : DB::Database) : Nil
    connection.exec("INSERT INTO users
      VALUES ('5000', 'user1', 'User One', '1000', datetime('now', '-2 month'), NULL, datetime('now', '-30 seconds'), NULL, NULL, '0', NULL, '10', '1', '1', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('10000', 'user2', 'User Two', '100', datetime('now', '-1 month', '-3 days'), NULL, datetime('now'), NULL, NULL, '0', NULL, '16', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('600000', 'user3', 'User Three', '100', datetime('now', '-1 month', '+10 days' ), NULL, datetime('now', '-1 minute'),NULL, NULL, '0', NULL, '8', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('40000', 'user4', 'User Four', '10', datetime('now', '-3 days'), NULL, datetime('now', '-3 days'), NULL, NULL, '0', NULL, '23', '1', '1', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('2000', 'user5', 'User Five', '10', datetime('now', '-8 days'), NULL, datetime('now', '-4 hours'), NULL, NULL, '0', NULL, '32', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('9000', 'user6', 'User Six', '0', datetime('now', '-14 days'), NULL, datetime('now', '-10 days'), NULL, NULL, '0', NULL, '44', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('110000', 'user7', 'User Seven', '0', datetime('now', '-13 days'), NULL, datetime('now', '-11 days'), datetime('now', '+4 hours'), NULL, '0', NULL, '50', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('22000', 'user8', 'User Eight', '0', datetime('now', '-6 days'), NULL, datetime('now', '-2 days'), NULL, NULL, '0', NULL, '13', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('550000', 'user9', 'User Nine', '0', datetime('now', '-4 days'), NULL, datetime('now', '-5 minutes'), NULL, NULL, '2', datetime('now', '+7 days'), '-20', '0', '1', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('34000', 'user10', 'User Ten', '-10', datetime('now', '-4 days'), datetime('now', '-3 days'), datetime('now', '-3 days'), datetime('now', '+10 days'), 'No Reason', '7', datetime('now', '+15 days'), '-70', '0', '0', NULL);
    ")
    connection.exec("INSERT INTO users
      VALUES ('77000', 'user11', 'User Eleven', '-10', datetime('now', '-12 days'), datetime('now', '-11 days'), datetime('now', '-11 days'), datetime('now', '+2 days'), NULL, '4', datetime('now', '+3 days'), '-50', '0', '0', 'Example#Test');
    ")
    connection.exec("INSERT INTO users
      VALUES ('870000', 'user12', 'User Twelve', '0', datetime('now', '-2 days'), datetime('now'), datetime('now'), NULL, NULL, '0', NULL, '2', '0', '0', NULL);
    ")
  end

  def self.generate_origins(connection : DB::Database) : Nil
    connection.exec("INSERT INTO text VALUES('test')")
    connection.exec("INSERT INTO text VALUES('test two')")
    connection.exec("INSERT INTO text VALUES('test three')")

    connection.exec("INSERT INTO file_id VALUES('10')")
    connection.exec("INSERT INTO file_id VALUES('20')")
    connection.exec("INSERT INTO file_id VALUES('30')")
    connection.exec("INSERT INTO file_id VALUES('40')")
  end

  describe SQLiteStatistics do
    describe "#initialize" do
      it "creates message data schema with default values" do
        int_fields = [
          "albums",
          "animations",
          "audio",
          "contacts",
          "documents",
          "forwards",
          "locations",
          "photos",
          "polls",
          "stickers",
          "text",
          "venues",
          "videos",
          "videonotes",
          "voice",
          "upvotes",
          "downvotes",
          "unoriginal_text",
          "unoriginal_media",
          "total_messages",
        ]

        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        connection.exec("INSERT INTO message_stats (date) VALUES (date('now'))")

        time = Time.utc

        date = connection.query_one("SELECT date FROM message_stats WHERE date = date(?)", time, as: String)
        date.should(eq(time.to_s("%Y-%m-%d")))

        int_fields.each do |field|
          result = connection.query_one("SELECT #{field} FROM message_stats WHERE date = date(?)", time, as: Int32)
          result.should(eq(0))
        end
      end

      it "sets statistics module start date" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        result = connection.query_one?("SELECT value FROM system_config WHERE name = 'start_date'", as: String)

        unless result
          fail("The value for 'start_date' in system_config should be set")
        end

        result.should(eq(Time.utc.to_s("%Y-%m-%d")))
      end
    end

    describe "#start_date" do
      it "gets statistics module start date" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        connection.exec("UPDATE system_config SET value = '1984-07-07' WHERE name = 'start_date'")

        stats.start_date.should(eq("1984-07-07"))
      end
    end

    describe "#increment_messages"  do
      it "increments the given field and total messages" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.increment_messages(Statistics::Messages::Audio)

        result_one = connection.query_one("SELECT audio, total_messages FROM message_stats WHERE date = date('now')", as: {Int32, Int32})

        result_one[0].should(eq(1))
        result_one[1].should(eq(1))

        stats.increment_messages(Statistics::Messages::Stickers)

        result_two = connection.query_one("SELECT stickers, audio, total_messages FROM message_stats WHERE date = date('now')", as: {Int32, Int32, Int32})

        result_two[0].should(eq(1))
        result_two[1].should(eq(1))
        result_two[2].should(eq(2))
      end
    end

    describe "#increment_upvotes" do
      it "increments the total number of upvotes" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.increment_upvotes()

        result = connection.query_one("SELECT upvotes FROM message_stats WHERE date = date('now')", as: Int32)

        result.should(eq(1))
      end
    end

    describe "#increment_downvotes" do
      it "increments the total number of downvotes" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.increment_downvotes()

        result = connection.query_one("SELECT downvotes FROM message_stats WHERE date = date('now')", as: Int32)

        result.should(eq(1))
      end
    end

    describe "#increment_unoriginal_text" do
      it "increments the total number of unoriginal text messages" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.increment_unoriginal_text()

        result = connection.query_one("SELECT unoriginal_text FROM message_stats WHERE date = date('now')", as: Int32)

        result.should(eq(1))
      end
    end

    describe "#increment_unoriginal_media" do
      it "increments the total number of unoriginal media messages" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.increment_unoriginal_media()

        result = connection.query_one("SELECT unoriginal_media FROM message_stats WHERE date = date('now')", as: Int32)

        result.should(eq(1))
      end
    end

    describe "#total_messages" do
      it "returns hash of messages totals for each type and totals over time" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        generate_message_stats(connection)

        result = stats.message_counts()

        result[Statistics::Messages::TotalMessages].should(eq(484))
        result[Statistics::Messages::Albums].should(eq(28))
        result[Statistics::Messages::Animations].should(eq(32))
        result[Statistics::Messages::Audio].should(eq(13))
        result[Statistics::Messages::Contacts].should(eq(41))
        result[Statistics::Messages::Documents].should(eq(33))
        result[Statistics::Messages::Forwards].should(eq(27))
        result[Statistics::Messages::Locations].should(eq(66))
        result[Statistics::Messages::Photos].should(eq(17))
        result[Statistics::Messages::Polls].should(eq(5))
        result[Statistics::Messages::Stickers].should(eq(39))
        result[Statistics::Messages::Text].should(eq(5))
        result[Statistics::Messages::Venues].should(eq(30))
        result[Statistics::Messages::Videos].should(eq(6))
        result[Statistics::Messages::VideoNotes].should(eq(25))
        result[Statistics::Messages::Voice].should(eq(50))
        result[Statistics::Messages::MessagesDaily].should(eq(22))
        result[Statistics::Messages::MessagesYesterday].should(eq(24))
        result[Statistics::Messages::MessagesWeekly].should(eq(118))
        result[Statistics::Messages::MessagesYesterweek].should(eq(192))
        result[Statistics::Messages::MessagesMonthly].should(eq(310))
        result[Statistics::Messages::MessagesYestermonth].should(eq(174))
      end
    end

    describe "#user_counts" do
      it "returns hash of user counts for each type and user count change over time" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        generate_user_stats(connection)

        result = stats.user_counts

        result[Statistics::Users::TotalUsers].should(eq(12))
        result[Statistics::Users::TotalJoined].should(eq(9))
        result[Statistics::Users::TotalLeft].should(eq(3))
        result[Statistics::Users::TotalBlacklisted].should(eq(2))
        result[Statistics::Users::JoinedDaily].should(eq(0))
        result[Statistics::Users::JoinedYesterday].should(eq(0))
        result[Statistics::Users::JoinedWeekly].should(eq(5))
        result[Statistics::Users::JoinedYesterweek].should(eq(3))
        result[Statistics::Users::JoinedMonthly].should(eq(10))
        result[Statistics::Users::JoinedYestermonth].should(eq(1))
        result[Statistics::Users::LeftDaily].should(eq(1))
        result[Statistics::Users::LeftYesterday].should(eq(0))
        result[Statistics::Users::LeftWeekly].should(eq(2))
        result[Statistics::Users::LeftYesterweek].should(eq(1))
        result[Statistics::Users::LeftMonthly].should(eq(3))
        result[Statistics::Users::LeftYestermonth].should(eq(0))
      end
    end

    describe "#karma_counts" do
      it "returns hash of karma counts and karma count change over time" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        generate_message_stats(connection)
        
        result = stats.karma_counts

        result[Statistics::Karma::TotalUpvotes].should(eq(3))
        result[Statistics::Karma::TotalDownvotes].should(eq(40))
        result[Statistics::Karma::UpvotesDaily].should(eq(0))
        result[Statistics::Karma::UpvotesYesterday].should(eq(3))
        result[Statistics::Karma::UpvotesWeekly].should(eq(3))
        result[Statistics::Karma::UpvotesYesterweek].should(eq(0))
        result[Statistics::Karma::UpvotesMonthly].should(eq(3))
        result[Statistics::Karma::UpvotesYestermonth].should(eq(0))
        result[Statistics::Karma::DownvotesDaily].should(eq(2))
        result[Statistics::Karma::DownvotesYesterday].should(eq(0))
        result[Statistics::Karma::DownvotesWeekly].should(eq(8))
        result[Statistics::Karma::DownvotesYesterweek].should(eq(20))
        result[Statistics::Karma::DownvotesMonthly].should(eq(28))
        result[Statistics::Karma::DownvotesYestermonth].should(eq(12))
      end
    end

    describe "#karma_level_count" do
      it "returns total number of users with karma between the given values" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        generate_user_stats(connection)

        result_one = stats.karma_level_count(-100, 0)
        result_one.should(eq(3))

        result_two = stats.karma_level_count(0, 10)
        result_two.should(eq(2))

        result_three = stats.karma_level_count(16, 44)
        result_three.should(eq(3))

        result_four = stats.karma_level_count(100, 200)
        result_four.should(eq(0))
      end
    end

    describe "#robot9000_counts" do
      it "returns hash of total original messages and unoriginal message counts" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)
        stats = SQLiteStatistics.new(connection)

        generate_message_stats(connection)
        generate_origins(connection)

        results = stats.robot9000_counts

        results[Statistics::Robot9000::TotalUnique].should(eq(7))
        results[Statistics::Robot9000::UniqueText].should(eq(3))
        results[Statistics::Robot9000::UniqueMedia].should(eq(4))
        results[Statistics::Robot9000::TotalUnoriginal].should(eq(48))
        results[Statistics::Robot9000::UnoriginalText].should(eq(25))
        results[Statistics::Robot9000::UnoriginalMedia].should(eq(23))
      end
    end

    describe "#ensure_schema" do
      it "creates message_stats table" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        connection.exec("DROP TABLE IF EXISTS message_stats")

        stats.ensure_schema()

        result = connection.query_one?("
          SELECT EXISTS (
            SELECT name FROM sqlite_schema WHERE type='table' AND name='message_stats'
          )", 
          as: Int32
        )

        result.should(eq(1))
      end

      it "creates proper schema" do
        fields = [
          "message_stats",
          "date TIMESTAMP NOT NULL",
          "albums INTEGER NOT NULL DEFAULT 0",
          "animations INTEGER NOT NULL DEFAULT 0",
          "audio INTEGER NOT NULL DEFAULT 0",
          "contacts INTEGER NOT NULL DEFAULT 0",
          "documents INTEGER NOT NULL DEFAULT 0",
          "forwards INTEGER NOT NULL DEFAULT 0",
          "locations INTEGER NOT NULL DEFAULT 0",
          "photos INTEGER NOT NULL DEFAULT 0",
          "polls INTEGER NOT NULL DEFAULT 0",
          "stickers INTEGER NOT NULL DEFAULT 0",
          "text INTEGER NOT NULL DEFAULT 0",
          "venues INTEGER NOT NULL DEFAULT 0",
          "videos INTEGER NOT NULL DEFAULT 0",
          "videonotes INTEGER NOT NULL DEFAULT 0",
          "voice INTEGER NOT NULL DEFAULT 0",
          "upvotes INTEGER NOT NULL DEFAULT 0",
          "downvotes INTEGER NOT NULL DEFAULT 0",
          "unoriginal_text INTEGER NOT NULL DEFAULT 0",
          "unoriginal_media INTEGER NOT NULL DEFAULT 0",
          "total_messages INTEGER NOT NULL DEFAULT 0",
          "PRIMARY KEY (date)",
        ]
        
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        connection.exec("DROP TABLE IF EXISTS message_stats")

        stats.ensure_schema()

        result = connection.query_one?("
          SELECT sql FROM sqlite_schema WHERE type='table' AND name='message_stats'", 
          as: String
        )

        unless result
          fail("The database should have a 'message_stat' table schema")
        end

        fields.each do |necessary_field|
          result.should(contain(necessary_field))
        end
      end
    end

    describe "#ensure_start_date" do
      it "sets statistics module start date" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        stats.ensure_start_date()

        result = connection.query_one?("SELECT value FROM system_config WHERE name = 'start_date'", as: String)

        unless result
          fail("The value for 'start_date' in system_config should be set")
        end

        result.should(eq(Time.utc.to_s("%Y-%m-%d")))
      end
    end
  end
end