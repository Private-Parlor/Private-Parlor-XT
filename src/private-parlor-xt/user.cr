require "./constants.cr"

module PrivateParlorXT
  
  # A reprentation of a Telegram user.
  # 
  # All users require an ID, which is obtained from the Telegram user (`Tourmaline::User`).
  # This ID should be unique and stored as a `UserID`.
  # 
  # `Database` implementations should have their own `User` type that inherits 
  # from this class and is modified to work with the given implementation.
  abstract class User

    # Returns the user's ID
    getter id : UserID

    # Returns the user's unformatted username, or `nil` if it does not exist
    getter username : String? = nil

    # Returns the user's full name
    getter realname : String = ""

    # Returns the user's current rank value
    getter rank : Int32 = 0

    # Returns the `Time` the user joined the chat
    getter joined : Time = Time.utc

    # Returns the `Time` the user left the chat, or `nil` if the user has not left
    getter left : Time? = nil

    # Returns the `Time` the user was last active (i.e., the last time a message was sent or a command was used)
    getter last_active : Time = Time.utc

    # Returns the `Time` until which the user is in cooldown, or `nil` if the user is not cooldowned
    getter cooldown_until : Time? = nil

    # Returns the reason why the user was blacklisted, or `nil` if a reason does not exist
    getter blacklist_reason : String? = nil

    # Returns the number of warnings the user has
    getter warnings : Int32 = 0

    # Returns the `Time` when one of the `warnings` will expire, or `nil` if such a time does not exit
    getter warn_expiry : Time? = nil

    # Returns the user's current amount of karma
    getter karma : Int32 = 0

    # Returns true if the user has karma notifications disabled, `false` otherwise
    getter hide_karma : Bool? = false

    # Returns true if the suer has debug mode enabled, `false` otherwise
    getter debug_enabled : Bool? = false

    # Returns a `String` containing the user's tripcode name and password for generating tripcodes, or `nil` if the user has no tripcode set
    getter tripcode : String? = nil

    # Creates an instance of `User`.
    #
    # ## Arguments:
    #
    # `id`
    # :     unique `UserID` identifier for this user
    #
    # `username`
    # :     username of this user; can be `nil`
    #
    # `realname`
    # :     full name (first name + last name) of the user
    #
    # `rank`
    # :     rank of this user, corresponding to either -10 (blacklisted) or one of the configurable ranks
    #
    # `joined`
    # :     date and time the user joined the chat
    # 
    # `left`
    # :     date and time the user left the chat; if `nil`, the user is still in the chat
    # 
    # `last_active`
    # :     date and time the user last sent a message or used a command
    #
    # `cooldown_until`
    # :     date and time for until which the user cannot send messages; if `nil`, the user is not in cooldown
    # 
    # `blacklist_reason`
    # :     described reason for blacklisting the user (see`BlacklistCommand`) ; set to `nil` by default
    # 
    # `warnings`
    # :     number of warnings the user received from `WarnCommand` or `DeleteCommand`; cooldown times are based off of this value
    #
    # `warn_expiry`
    # :     date and time in which one of the `warnings` will be removed; if `nil`, user has no `warnings` to remove
    # 
    # `karma`
    # :     points the user acquired from upvotes, or lost from downvotes and warnings (see `UpvoteHandler`, `DownvoteHandler`)
    # 
    # `hide_karma`
    # :     toggle for receiving karma notifications (see `ToggleKarmaCommand`); if `true`, the user will not receive karma notifications
    #
    # `debug_enabled`
    # :     toggle for debug mode (see `ToggleDebugCommand`); if `true`, the user will receive a copy of their sent message that everyone else received
    # 
    # `tripcode`
    # :     a name and password pairing used for generating pseudononyms attached to the user's message; if nil, user has no tripcode
    def initialize(
      @id : UserID,
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
    def to_a : Array(UserID | String | Int32 | Time | Bool | Nil)
      {% begin %}
        [
        {% for var in User.instance_vars[0..-2] %}
          @{{var.id}},
        {% end %}
          @{{User.instance_vars.last.id}}
        ]
      {% end %}
    end

    # Get the formatted name of the user.
    # If the user has a `username`, returns it with the '@' prepended to it
    # Otherwise, returns the `realname`
    def formatted_name : String
      if username = @username
        "@" + username
      else
        @realname
      end
    end

    # Generate an obfuscated ID for the user, used for log messages and commands like `InfoCommand`
    def obfuscated_id : String
      # With 64 possible Base64 characters, this should give us 766,480 possible OIDs
      Random.new(@id + Time.utc.at_beginning_of_day.to_unix).base64(3)
    end

    # Get the user's obfuscated `karma`
    def obfuscated_karma : Int32
      offset = ((@karma * 0.2).abs + 2).round.to_i
      @karma + Random.rand(0..(offset + 1)) - offset
    end

    # Set `left` to `nil`, meaning that the User has joined the chat.
    def rejoin : Nil
      @left = nil
    end

    # Sets user's `username` and `realname` to the given values
    def update_names(username : String | Nil, fullname : String) : Nil
      @username = username
      @realname = fullname
    end

    # Set `last_active` to the current time
    def set_active : Nil
      @last_active = Time.utc
    end

    # Set `left` to the current time
    def set_left : Nil
      @left = Time.utc
    end

    # Set `rank` to the given value
    def set_rank(rank : Int32) : Nil
      @rank = rank
    end

    # Set `tripcode` to the given value
    def set_tripcode(tripcode : String) : Nil
      @tripcode = tripcode
    end

    # Switches user's `hide_karma` notifications toggle
    def toggle_karma : Nil
      @hide_karma = !hide_karma
    end

    # Switches user's `debug_enabled` toggle
    def toggle_debug : Nil
      @debug_enabled = !debug_enabled
    end

    # Increment the user's `karma` by a given amount (1 by default)
    # On arithmetic overflow, sets user's `karma` to the maximum `Int32` value
    def increment_karma(amount : Int32 = 1) : Nil
      @karma += amount
    rescue OverflowError
      @karma = Int32::MAX
    end

    # Decrement the user's `karma` by a given amount (1 by default)
    # On arithmetic overflow, sets user's `karma` to the minimum `Int32` value
    def decrement_karma(amount : Int32 = 1) : Nil
      @karma -= amount
    rescue OverflowError
      @karma = Int32::MIN
    end

    # Gives the user an exponentially increasing cooldown from the given *base* value and current number of `warnings`
    def cooldown(base : Int32) : Time::Span
      begin
        warnings = @warnings
        if @warnings < 0
          warnings = 0
        end
        duration = base ** warnings
      rescue OverflowError
        duration = 525950
      end

      if duration > 525950
        duration = 52.weeks
      else
        duration = duration.minutes
      end

      @cooldown_until = Time.utc + duration

      duration
    end

    # Gives the user a cooldown based on the given `Time::Span`
    def cooldown(time : Time::Span) : Time::Span
      @cooldown_until = Time.utc + time

      time
    end

    # Increments the user's `warnings` and sets the `warn_expiry` to the current time plus the *lifespan* of a warning
    def warn(lifespan : Int32) : Nil
      @warnings += 1
      @warn_expiry = Time.utc + lifespan.hours
    end

    # Set the user's `rank` to -10 (blacklisted), sets the `left` value, and updates the `blacklist_reason`
    def blacklist(reason : String?) : Nil
      @rank = -10
      self.set_left
      @blacklist_reason = reason
    end

    # Removes a cooldown from a user if it has expired.
    #
    # Returns `true` if the cooldown can be expired, `false` otherwise
    def remove_cooldown(override : Bool = false) : Bool
      return true unless cooldown = @cooldown_until

      return false unless cooldown < Time.utc || override

      @cooldown_until = nil

      true
    end

    # Removes the given *amount* of `warnings` from a user
    # 
    # If the user still has `warnings` after the removal, reset the `warn_expiry` to a later time based on *warn_lifespan*
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

    # Returns `true` if *left* is not `nil`; user has left the chat.
    #
    # Returns `false` otherwise.
    def left? : Bool
      @left != nil
    end

    # Returns `true` if user is joined, not in cooldown, and not blacklisted; user can chat
    #
    # Returns `false` otherwise.
    def can_chat? : Bool
      self.remove_cooldown && self.can_use_command?
    end

    # Returns `true` if user is joined, not in cooldown, not blacklisted, and not limited; user can chat
    #
    # Returns `false` otherwise.
    def can_chat?(limit : Time::Span) : Bool
      if self.rank > 0
        self.can_chat?
      else
        self.remove_cooldown && self.can_use_command? && (Time.utc - self.joined > limit)
      end
    end

    # Returns `true` if user is joined and not blacklisted; user can use commands
    #
    # Returns `false` otherwise.
    def can_use_command? : Bool
      !self.blacklisted? && !self.left?
    end
  end
end
