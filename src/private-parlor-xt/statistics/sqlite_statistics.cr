require "../constants.cr"
require "./statistics.cr"
require "db"

module PrivateParlorXT
  # An implementation of `Statistics` using the `Database` for storing message data
  class SQLiteStatistics < Statistics
    # Generally this should use the same connection that was used for the database
    def initialize(@connection : DB::Database)
      ensure_schema()
      ensure_start_date()
    end

    # Wrapper intended for exec statements. Used to handle SQLite3 exceptions
    private def write(&block)
      yield
    rescue ex : SQLite3::Exception
      if ex.code == 5 # DB is locked
        sleep(10.milliseconds)
        write(&block)
      end
    end

    # :inherit:
    def start_date : String
      @connection.query_one("
        SELECT value
        FROM system_config
        WHERE name = 'start_date'",
        as: String
      )
    end

    # :inherit:
    def increment_messages(type : Messages) : Nil
      column = type.to_s.downcase

      write do
        @connection.exec("
          INSERT INTO message_stats (date, #{column}, total_messages)
          VALUES (date('now'), 1, 1)
          ON CONFLICT(date) DO UPDATE SET #{column} = #{column} + 1, total_messages = total_messages + 1 WHERE date = date('now')
        ")
      end
    end

    # :inherit:
    def increment_upvotes : Nil
      write do
        @connection.exec("
          INSERT INTO message_stats (date, upvotes)
          VALUES (date('now'), 1)
          ON CONFLICT(date) DO UPDATE SET upvotes = upvotes + 1 WHERE date = date('now')
        ")
      end
    end

    # :inherit:
    def increment_downvotes : Nil
      write do
        @connection.exec("
          INSERT INTO message_stats (date, downvotes)
          VALUES (date('now'), 1)
          ON CONFLICT(date) DO UPDATE SET downvotes = downvotes + 1 WHERE date = date('now')
        ")
      end
    end

    # :inherit:
    def increment_unoriginal_text : Nil
      write do
        @connection.exec("
          INSERT INTO message_stats (date, unoriginal_text)
          VALUES (date('now'), 1)
          ON CONFLICT(date) DO UPDATE SET unoriginal_text = unoriginal_text + 1 WHERE date = date('now')
        ")
      end
    end

    # :inherit:
    def increment_unoriginal_media : Nil
      write do
        @connection.exec("
          INSERT INTO message_stats (date, unoriginal_media)
          VALUES (date('now'), 1)
          ON CONFLICT(date) DO UPDATE SET unoriginal_media = unoriginal_media + 1 WHERE date = date('now')
        ")
      end
    end

    # :inherit:
    def message_counts : Hash(Messages, Int32)
      totals = @connection.query_one("
        SELECT
          coalesce(sum(total_messages), 0) as total_messages,
          coalesce(sum(albums), 0) as albums,
          coalesce(sum(animations), 0) as animations,
          coalesce(sum(audio), 0) as audio,
          coalesce(sum(contacts), 0) as contacts,
          coalesce(sum(documents), 0) as documents,
          coalesce(sum(forwards), 0) as forwards,
          coalesce(sum(locations), 0) as locations,
          coalesce(sum(photos), 0) as photos,
          coalesce(sum(polls), 0) as polls,
          coalesce(sum(stickers), 0) as stickers,
          coalesce(sum(text), 0) as text,
          coalesce(sum(venues), 0) as venues,
          coalesce(sum(videos), 0) as videos,
          coalesce(sum(videonotes), 0) as videonotes,
          coalesce(sum(voice), 0) as voice,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date = date('now')) as messages_daily,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date = date('now','-1 day')) as messages_yesterday,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date > date('now','-7 days')) as messages_weekly,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date <= date('now','-7 days') AND date > date('now','-14 days')) as messages_yesterweek,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date > date('now','-1 month')) as messages_monthly,
          (select coalesce(sum(total_messages), 0) FROM message_stats WHERE date <= date('now','-1 month') AND date > date('now','-2 months')) as messages_yestermonth
        FROM message_stats",
        as: {
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32,
        }
      )

      Hash.zip(Messages.values, totals.to_a)
    end

    # :inherit:
    def user_counts : Hash(Users, Int32)
      totals = @connection.query_one("
        SELECT
          count(id) as total_users,
          (SELECT count(id) FROM users WHERE left IS null) as total_joined,
          count(left) as total_left,
          (SELECT count(id) FROM users WHERE rank = -10) as total_blacklisted,
          (SELECT count(id) FROM users WHERE date(joined) = date('now')) as joined_daily,
          (SELECT count(id) FROM users WHERE date(joined) = date('now','-1 day')) as joined_yesterday,
          (select count(id) FROM users WHERE date(joined) > date('now','-7 days')) as joined_weekly,
          (select count(id) FROM users WHERE date(joined) < date('now','-7 days') AND date(joined) > date('now','-14 days')) as joined_yesterweek,
          (select count(id) FROM users WHERE date(joined) > date('now','-1 month')) as joined_monthly,
          (select count(id) FROM users WHERE date(joined) < date('now','-1 month') AND date(joined) > date('now','-2 months')) as joined_yestermonth,
          (SELECT count(id) FROM users WHERE date(left) = date('now')) as left_daily,
          (SELECT count(id) FROM users WHERE date(left) = date('now','-1 day')) as left_yesterday,
          (select count(id) FROM users WHERE date(left) > date('now','-7 days')) as left_weekly,
          (select count(id) FROM users WHERE date(left) <= date('now','-7 days') AND date(left) > date('now','-14 days')) as left_yesterweek,
          (select count(id) FROM users WHERE date(left) > date('now','-1 month')) as left_monthly,
          (select count(id) FROM users WHERE date(left) <= date('now','-1 month') AND date(left) > date('now','-2 months')) as left_yestermonth
        FROM users",
        as: {
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32,
        }
      )

      Hash.zip(Users.values, totals.to_a)
    end

    # :inherit:
    def karma_counts : Hash(Karma, Int32)
      totals = @connection.query_one("
        SELECT
          coalesce(sum(upvotes), 0) as total_upvotes,
          coalesce(sum(downvotes), 0) as total_downvotes,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date = date('now')) as upvotes_daily,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date = date('now','-1 day')) as upvotes_yesterday,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date > date('now','-7 days')) as upvotes_weekly,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date < date('now','-7 days') AND date > date('now','-14 days')) as upvotes_yesterweek,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date > date('now','-1 month')) as upvotes_monthly,
          (select coalesce(sum(upvotes), 0) FROM message_stats WHERE date < date('now','-1 month') AND date > date('now','-2 months')) as upvotes_yestermonth,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date = date('now')) as downvotes_daily,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date = date('now','-1 day')) as downvotes_yesterday,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date > date('now','-7 days')) as downvotes_weekly,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date <= date('now','-7 days') AND date > date('now','-14 days')) as downvotes_yesterweek,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date > date('now','-1 month')) as downvotes_monthly,
          (select coalesce(sum(downvotes), 0) FROM message_stats WHERE date <= date('now','-1 month') AND date > date('now','-2 months')) as downvotes_yestermonth
        FROM message_stats",
        as: {
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32, Int32,
        }
      )

      Hash.zip(Karma.values, totals.to_a)
    end

    # :inherit:
    def karma_level_count(start_value : Int32, end_value : Int32) : Int32
      @connection.query_one("
        SELECT count(id)
        FROM users
        WHERE karma >= ? AND karma < ?",
        args: [start_value, end_value],
        as: Int32
      )
    end

    # :inherit:
    def robot9000_counts : Hash(Robot9000, Int32)
      totals = @connection.query_one("
        SELECT
          (SELECT count(id) FROM (SELECT * FROM file_id UNION SELECT * FROM text)) as total_unique,
          (SELECT count(line) FROM text) as unique_text,
          (SELECT count(id) FROM file_id) as unique_media,
          (SELECT coalesce(sum(unoriginal_text + unoriginal_media), 0) FROM message_stats) as total_unoriginal,
          (SELECT coalesce(sum(unoriginal_text), 0) FROM message_stats) as unoriginal_text,
          (SELECT coalesce(sum(unoriginal_media), 0) FROM message_stats) as unoriginal_media",
        as: {
          Int32, Int32, Int32,
          Int32, Int32, Int32,
        }
      )

      Hash.zip(Robot9000.values, totals.to_a)
    end

    # Ensures that there is a 'message_stats' table in the database
    def ensure_schema : Nil
      write do
        @connection.exec("CREATE TABLE IF NOT EXISTS message_stats (
          date TIMESTAMP NOT NULL,
          albums INTEGER NOT NULL DEFAULT 0,
          animations INTEGER NOT NULL DEFAULT 0,
          audio INTEGER NOT NULL DEFAULT 0,
          contacts INTEGER NOT NULL DEFAULT 0,
          documents INTEGER NOT NULL DEFAULT 0,
          forwards INTEGER NOT NULL DEFAULT 0,
          locations INTEGER NOT NULL DEFAULT 0,
          photos INTEGER NOT NULL DEFAULT 0,
          polls INTEGER NOT NULL DEFAULT 0,
          stickers INTEGER NOT NULL DEFAULT 0,
          text INTEGER NOT NULL DEFAULT 0,
          venues INTEGER NOT NULL DEFAULT 0,
          videos INTEGER NOT NULL DEFAULT 0,
          videonotes INTEGER NOT NULL DEFAULT 0,
          voice INTEGER NOT NULL DEFAULT 0,
          upvotes INTEGER NOT NULL DEFAULT 0,
          downvotes INTEGER NOT NULL DEFAULT 0,
          unoriginal_text INTEGER NOT NULL DEFAULT 0,
          unoriginal_media INTEGER NOT NULL DEFAULT 0,
          total_messages INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (date)
        )")
      end
    end

    # Ensures that there is a date value for the 'start_date' key in the 'system_config' table
    def ensure_start_date : Nil
      return if @connection.query_one?("SELECT value FROM system_config WHERE name = 'start_date'", as: String)

      write do
        @connection.exec("INSERT INTO system_config VALUES ('start_date', date(?))", Time.utc)
      end
    end
  end
end
