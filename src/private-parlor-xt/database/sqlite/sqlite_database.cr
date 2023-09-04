require "../../database.cr"
require "sqlite3"

module PrivateParlorXT
  class SQLiteDatabase < Database
    @connection : DB::Connection

    private def initialize(@connection : DB::Connection)
    end

    def self.instance(connection : DB::Connection)
      @@instance ||= new(connection)
    end

  end
end