require "../constants.cr"
require "../history.cr"
require "db"

module PrivateParlorXT

  # An implementation of `History` using the SQLite `Database` for storing message data
  class SQLiteHistory < History
    @connection : DB::Database

    # :inherit:
    #
    # Generally this should use the same connection that was used for the database
    def initialize(@lifespan : Time::Span, @connection : DB::Database)
      ensure_schema()
    end

    # Closes the databsase connection
    def close
      @connection.close
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
    def new_message(sender_id : UserID, origin : MessageID) : MessageID
      write do
        @connection.exec(
          "INSERT INTO message_groups VALUES (?, ?, ?, ?)",
          args: [origin, sender_id, Time.utc, false]
        )
      end

      origin
    end

    # :inherit:
    def add_to_history(origin : MessageID, receiver : MessageID, receiver_id : UserID) : Nil
      write do
        @connection.exec(
          "INSERT INTO receivers VALUES (?, ?, ?)",
          args: [receiver, receiver_id, origin]
        )
      end
    end

    # :inherit:
    def get_origin_message(message : MessageID) : MessageID?
      @connection.query_one?(
        "SELECT messageGroupID
        FROM receivers
        where receiverMSID = ?
        UNION
        select messageGroupID
        FROM message_groups
        WHERE messageGroupID = ?",
        message, message,
        as: MessageID
      )
    end

    # :inherit:
    def get_all_receivers(message : MessageID) : Hash(UserID, MessageID)
      origin_msid = get_origin_message(message)

      @connection.query_all(
        "SELECT senderID, messageGroupID
        FROM message_groups
        WHERE messageGroupID = ?
        UNION
        SELECT receiverID, receiverMSID
        FROM receivers
        WHERE messageGroupID = ?",
        origin_msid, origin_msid,
        as: {UserID, MessageID}
      ).to_h
    end

    # :inherit:
    def get_receiver_message(message : MessageID, receiver : UserID) : MessageID?
      get_all_receivers(message)[receiver]?
    end

    # :inherit:
    def get_sender(message : MessageID) : UserID?
      @connection.query_one?(
        "SELECT DISTINCT senderID
        FROM message_groups
        WHERE messageGroupID IN (
          SELECT messageGroupID
          FROM receivers
          WHERE receiverMSID = ?
        )
        OR messageGroupID = ?",
        message, message,
        as: UserID
      )
    end

    # :inherit:
    def get_messages_from_user(user : UserID) : Set(MessageID)
      @connection.query_all(
        "SELECT messageGroupID
        FROM message_groups
        WHERE senderID = ? AND sentTime > ?",
        args: [user, (Time.utc - 48.hours)],
        as: MessageID
      ).to_set
    end

    # :inherit:
    def add_rating(message : MessageID, user : UserID) : Bool
      if @connection.query_one?("SELECT userID FROM karma WHERE messageGroupID = ? AND userID = ?", message, user, as: UserID)
        return false
      end

      write do
        @connection.exec("INSERT INTO karma VALUES (?, ?)", args: [message, user])
      end

      true
    end

    # :inherit:
    def add_warning(message : MessageID) : Nil
      write do
        @connection.exec(
          "UPDATE message_groups
          SET warned = TRUE
          WHERE messageGroupID = ?",
          get_origin_message(message)
        )
      end
    end

    # :inherit:
    def get_warning(message : MessageID) : Bool?
      @connection.query_one?(
        "SELECT warned
        FROM message_groups
        WHERE messageGroupID = ?",
        get_origin_message(message),
        as: Bool
      )
    end

    # :inherit:
    def get_purge_receivers(messages : Set(MessageID)) : Hash(UserID, Array(MessageID))
      hash = {} of UserID => Array(MessageID)

      tuples = @connection.query_all(
        "SELECT receiverID, receiverMSID
        FROM receivers
        WHERE receivers.messageGroupID IN (
          SELECT messageGroupID
          FROM message_groups
          WHERE messageGroupID in (#{messages.join(", ") { "?" }})
        )
        ORDER BY receiverMSID DESC",
        args: messages.to_a,
        as: {UserID, MessageID}
      )

      tuples.each do |tuple|
        if hash[tuple[0]]?
          hash[tuple[0]] << tuple[1]
        else
          hash[tuple[0]] = [tuple[1]]
        end
      end

      hash
    end

    # :inherit:
    def delete_message_group(message : MessageID) : MessageID?
      origin_msid = get_origin_message(message)

      write do
        @connection.exec("DELETE FROM message_groups WHERE messageGroupID = ?", origin_msid)
      end

      origin_msid
    end

    # :inherit:
    def expire : Nil
      count = @connection.query_one(
        "SELECT COUNT(messageGroupID)
        FROM message_groups
        WHERE sentTime <= ?",
        Time.utc - @lifespan,
        as: Int32
      )

      write do
        @connection.exec("DELETE FROM message_groups WHERE sentTime <= ?", Time.utc - @lifespan)
      end

      if count > 0
        Log.debug { "Expired #{count} messages from the cache" }
      end
    end

    # Ensures that there are message_group, receivers, and karma tables in the `Database`
    def ensure_schema : Nil
      write do
        @connection.exec("PRAGMA foreign_keys = ON")
        @connection.exec("CREATE TABLE IF NOT EXISTS message_groups (
          messageGroupID BIGINT NOT NULL,
          senderID BIGINT NOT NULL,
          sentTime TIMESTAMP NOT NULL,
          warned TINYINT NOT NULL,
          PRIMARY KEY (messageGroupID)
        )")
        @connection.exec("CREATE TABLE IF NOT EXISTS receivers (
          receiverMSID BIGINT NOT NULL,
          receiverID BIGINT NOT NULL,
          messageGroupID BIGINT NOT NULL,
          PRIMARY KEY (receiverMSID),
          FOREIGN KEY (messageGroupID) REFERENCES message_groups(messageGroupID)
          ON DELETE CASCADE
        )")
        @connection.exec("CREATE TABLE IF NOT EXISTS karma (
          messageGroupID BIGINT NOT NULL,
          userID BIGINT NOT NULL,
          PRIMARY KEY (messageGroupID),
          FOREIGN KEY (messageGroupID) REFERENCES receivers(receiverMSID)
          ON DELETE CASCADE
        )")
      end
    end
  end
end
