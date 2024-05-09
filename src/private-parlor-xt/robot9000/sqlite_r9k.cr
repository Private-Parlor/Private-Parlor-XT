require "../constants.cr"
require "../robot9000.cr"
require "db"

module PrivateParlorXT

  # An implementation of `Robot9000` using the `Database` to store unique text and media IDs
  class SQLiteRobot9000 < Robot9000
    @connection : DB::Database

    # Generally this should use the same connection that was used for the database
    def initialize(
      @connection : DB::Database,
      @valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)],
      @check_text : Bool? = nil,
      @check_media : Bool? = nil,
      @check_forwards : Bool? = nil,
      @warn_user : Bool? = nil,
      @cooldown : Int32 = 0
    )
      ensure_schema()
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
    def unoriginal_text?(text : String) : Bool?
      @connection.query_one?("SELECT 1 FROM text WHERE line = ?", text) do
        true
      end
    end

    # :inherit:
    def add_line(text : String) : Nil
      write do
        @connection.exec("INSERT INTO text VALUES (?)", text)
      end
    end

    # :inherit:
    def unoriginal_media?(id : String) : Bool?
      @connection.query_one?("SELECT 1 FROM file_id WHERE id = ?", id) do
        true
      end
    end

    # :inherit:
    def add_file_id(id : String) : Nil
      write do
        @connection.exec("INSERT INTO file_id VALUES (?)", id)
      end
    end

    # Ensures that the text table, file_id table, or both are created in the `Database`, according to the values of `check_text` and `check_media`
    def ensure_schema : Nil
      if @check_text
        write do
          @connection.exec("
            CREATE TABLE IF NOT EXISTS text (
              line TEXT NOT NULL,
              PRIMARY KEY (line)
            )
          ")
        end
      end
      if @check_media
        write do
          @connection.exec("
            CREATE TABLE IF NOT EXISTS file_id (
              id TEXT NOT NULL,
              PRIMARY KEY (id)
            )
          ")
        end
      end
    end
  end
end
