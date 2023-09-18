require "../database.cr"
require "sqlite3"

module PrivateParlorXT
  class SQLiteDatabase < Database
    @connection : DB::Database

    # :inherit:
    def initialize(@connection : DB::Database)
      ensure_schema()
    end

    # :inherit:
    def self.instance(connection : DB::Database)
      @@instance ||= new(connection)
    end

    # :inherit:
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
    def get_user(id : UserID?) : User?
      @connection.query_one?("SELECT * FROM users WHERE id = ?", id, as: SQLiteUser)
    end

    # :inherit:
    def get_user_counts : NamedTuple(total: Int32, left: Int32, blacklisted: Int32)
      @connection.query_one(
        "SELECT COUNT(id), COUNT(left), (SELECT COUNT(id) FROM users WHERE rank = -10) FROM users",
        as: {total: Int32, left: Int32, blacklisted: Int32}
      )
    end

    # :inherit:
    def get_blacklisted_users : Array(User)
      arr = [] of User
      arr = arr.concat(@connection.query_all("SELECT * FROM users WHERE rank = -10", as: SQLiteUser))
    end

    def get_blacklisted_users(time_limit : Time::Span) : Array(User)
      arr = [] of User
      arr.concat(@connection.query_all("SELECT * FROM users WHERE rank = -10 AND left > (?)", (Time.utc - time_limit), as: SQLiteUser))
    end

    # :inherit:
    def get_warned_users : Array(User)
      arr = [] of User
      arr.concat(@connection.query_all("SELECT * FROM users WHERE warnings > 0 AND left is NULL", as: SQLiteUser))
    end

    # :inherit:
    def get_invalid_rank_users(valid_ranks : Array(Int32)) : Array(User)
      arr = [] of User
      arr.concat(@connection.query_all("SELECT * FROM users WHERE rank NOT IN (#{valid_ranks.join(", ") { "?" }})", args: valid_ranks, as: SQLiteUser))
    end

    # :inherit:
    def get_inactive_users(time_limit : Time::Span) : Array(User)
      arr = [] of User
      arr.concat(@connection.query_all("SELECT * FROM users WHERE left is NULL AND lastActive < ?", (Time.utc - time_limit), as: SQLiteUser))
    end

    # :inherit:
    def get_user_by_name(username : String) : User?
      if username.starts_with?("@")
        username = username[1..]
      end
      @connection.query_one?("SELECT * FROM users WHERE LOWER(username) = ?", username, as: SQLiteUser)
    end

    # :inherit:
    def get_user_by_oid(oid : String) : User?
      @connection.query_all("SELECT * FROM users WHERE left IS NULL ORDER BY lastActive DESC", as: SQLiteUser).each do |user|
        if user.get_obfuscated_id == oid
          return user
        end
      end
    end

    # :inherit:
    def get_active_users : Array(UserID)
      @connection.query_all("SELECT id FROM users WHERE left IS NULL ORDER BY rank DESC, lastActive DESC", &.read(Int64))
    end

    # :inherit:
    def get_active_users(exclude : UserID) : Array(UserID)
      @connection.query_all("SELECT id
        FROM users
        WHERE left IS NULL AND id IS NOT ?
        ORDER BY rank DESC, lastActive DESC",
        args: [exclude],
        &.read(Int64)
      )
    end

    # :inherit:
    def add_user(id : UserID, username : String?, realname : String, rank : Int32) : User?
      user = SQLiteUser.new(id, username, realname, rank)

      {% begin %}
        {% arr = [] of ArrayLiteral %}
        {% for var in User.instance_vars %}
          {% arr << "?" %}
        {% end %}
        {% arr = arr.join(", ") %}

        # Add user to database
        write do
          @connection.exec("INSERT INTO users VALUES (#{{{arr}}})", args: user.to_array)
        end
      {% end %}

      user
    end

    # :inherit:
    def update_user(user : User) : Nil
      {% begin %}
        {% arr = [] of ArrayLiteral %}
        {% for var in User.instance_vars[1..-1] %}
          {% arr << "#{var.name.camelcase(lower: true)} = ?" %}
        {% end %}
        {% arr = arr.join(", ") %}
        # Modify user
        write do
          @connection.exec("UPDATE users SET #{{{arr}}} WHERE id = ?", args: user.to_array.rotate)
        end
      {% end %}
    end

    # :inherit:
    def no_users? : Bool?
      !@connection.query("SELECT id FROM users") do |rs|
        rs.move_next
      end
    end

    # :inherit:
    def expire_warnings(warn_lifespan : Time::Span)
      get_warned_users.each do |user|
        if expiry = user.warn_expiry
          if expiry <= Time.utc
            user.remove_warning(1, warn_lifespan)
            update_user(user)
          end
        end
      end
    end

    # :inherit:
    def set_motd(text : String) : Nil
      write do
        @connection.exec("REPLACE INTO system_config VALUES ('motd', ?)", text)
      end
    end

    # :inherit:
    def get_motd : String?
      @connection.query_one?("SELECT value FROM system_config WHERE name = 'motd'", as: String)
    end

    def ensure_schema : Nil
      write do
        @connection.exec("CREATE TABLE IF NOT EXISTS system_config (
          name TEXT NOT NULL,
          value TEXT NOT NULL,
          PRIMARY KEY (name)
        )")
        @connection.exec("CREATE TABLE IF NOT EXISTS users (
          id BIGINT NOT NULL,
          username TEXT,
          realname TEXT NOT NULL,
          rank INTEGER NOT NULL,
          joined TIMESTAMP NOT NULL,
          left TIMESTAMP,
          lastActive TIMESTAMP NOT NULL,
          cooldownUntil TIMESTAMP,
          blacklistReason TEXT,
          warnings INTEGER NOT NULL,
          warnExpiry TIMESTAMP,
          karma INTEGER NOT NULL,
          hideKarma TINYINT NOT NULL,
          debugEnabled TINYINT NOT NULL,
          tripcode TEXT,
          PRIMARY KEY(id)
        )")
      end
    end
  end
end
