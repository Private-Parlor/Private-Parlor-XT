require "./constants.cr"

module PrivateParlorXT
  abstract class User
    @id : UserID
    @username : String? = nil
    @realname : String = ""
    @rank : Int32 = 0
    @joined : Time = Time.utc
    @left : Time? = nil
    @last_active : Time = Time.utc
    @cooldown_until : Time? = nil
    @blacklist_reason : String? = nil
    @warnings : Int32 = 0
    @warn_expiry : Time? = nil
    @karma : Int32 = 0
    @hide_karma : Bool? = false
    @debug_enabled : Bool? = false
    @tripcode : String? = nil

    def initialize(
      @id : Int64,
      @username : String? = nil,
      @realname : String = "",
      @rank : Int32 = 0,
      @joined : Time = Time.utc,
      @left : Time? = nil,
      @last_active : Time = Time.utc,
      @cooldown_until : Time? = nil,
      @blacklist_reason : String? = nil,
      @warnings : Int32 = 0,
      @warn_expiry : Time? = nil,
      @karma : Int32 = 0,
      @hide_karma : Bool? = false,
      @debug_enabled : Bool? = false,
      @tripcode : String? = nil
    )
    end

    # Returns an array with all the values in `User`. Intended for database query arguments.
    def to_array
      {% begin %}
        [
        {% for var in User.instance_vars[0..-2] %}
          @{{var.id}},
        {% end %}
          @{{User.instance_vars.last.id}}
        ]
      {% end %}
    end

    def get_formatted_name : String
      if username = @username
        "@" + username
      else
        @realname
      end
    end

    def get_obfuscated_id : String
      Random.new(@id + Time.utc.at_beginning_of_day.to_unix).base64(3)
    end

    # Set *left* to nil, meaning that the User has joined the chat.
    def rejoin : Nil
      @left = nil
    end

    def update_names(username : String | Nil, fullname : String) : Nil
      @username = username
      @realname = fullname
    end

    # Set *last_active* to the current time
    def set_active : Nil
      @last_active = Time.utc
    end

    def set_left : Nil
      @left = Time.utc
    end

    def remove_warning(amount : Int32, warn_lifespan : Time::Span) : Nil
      @warnings -= amount

      if @warnings > 0
        @warn_expiry = Time.utc + warn_lifespan
      else
        @warn_expiry = nil
      end
    end

    # Returns `true` if *rank* is -10; user is blacklisted.
    #
    # Returns `false` otherwise.
    def blacklisted? : Bool
      @rank == -10
    end

    # Returns `true` if *left* is not nil; user has left the chat.
    #
    # Returns `false` otherwise.
    def left? : Bool
      @left != nil
    end
  end
end
