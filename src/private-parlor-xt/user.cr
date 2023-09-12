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

    def toggle_debug : Nil
      @debug_enabled = !debug_enabled
    end

    # Removes a cooldown from a user if it has expired.
    #
    # Returns true if the cooldown can be expired, false otherwise
    def remove_cooldown(override : Bool = false) : Bool
      if cooldown = @cooldown_until
        if cooldown < Time.utc || override
          @cooldown_until = nil
        else
          return false
        end
      end

      true
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

    # Returns `true` if user is joined, not in cooldown, and not blacklisted; user can chat
    #
    # Returns false otherwise.
    def can_chat? : Bool
      self.remove_cooldown && !self.blacklisted? && !self.left?
    end

    # Returns `true` if user is joined, not in cooldown, not blacklisted, and not limited; user can chat
    #
    # Returns false otherwise.
    def can_chat?(limit : Time::Span) : Bool
      if self.rank > 0
        self.can_chat?
      else
        self.remove_cooldown && !self.blacklisted? && !self.left? && (Time.utc - self.joined > limit)
      end
    end

    # Returns `true` if user is joined and not blacklisted; user can use commands
    #
    # Returns false otherwise.
    def can_use_command? : Bool
      !self.blacklisted? && !self.left?
    end
  end
end
