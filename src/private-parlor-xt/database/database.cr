require "../constants.cr"
require "../user.cr"

module PrivateParlorXT
  # A base class for `Database` implementations, used for storing and retrieving data about users
  abstract class Database
    # Creates an instance of `Database`
    def initialize
    end

    # Close connection to the `Database`
    def close
    end

    # Get user by `UserID`
    abstract def get_user(id : UserID?) : User?

    # Get the total count of users, users that have stopped the bot, and
    # users that are blacklisted
    abstract def user_counts : NamedTuple(total: Int32, left: Int32, blacklisted: Int32)

    # Get an array of blacklisted users
    abstract def blacklisted_users : Array(User)

    # Get an array of recently blacklisted users
    abstract def blacklisted_users(time_limit : Time::Span) : Array(User)

    # Get an array of warned users
    abstract def warned_users : Array(User)?

    # Get an array of users whose ranks are currently invalid
    abstract def invalid_rank_users(valid_ranks : Array(Int32)) : Array(User)?

    # Get users that have not been active within a given time limit
    abstract def inactive_users(time_limit : Time::Span) : Array(User)?

    # Get user by username
    abstract def get_user_by_name(username : String) : User?

    # Get user by a four-digit obfuscated ID
    abstract def get_user_by_oid(oid : String) : User?

    # Get user by a given arg, calling the appropriate function
    def get_user_by_arg(arg : String) : User?
      if arg.size == 4
        get_user_by_oid(arg)
      elsif (val = arg.to_i64?) && arg.matches?(/[0-9]{5,}/)
        get_user(val)
      else
        get_user_by_name(arg)
      end
    end

    # Queries the database for the most active users, ordered by highest ranking
    # users first, then most active users.
    abstract def active_users : Array(UserID)

    # :ditto:
    #
    # Use this to exclude a user from the result (i.e., when a user does not have
    # debug mode enabled)
    abstract def active_users(exclude : UserID) : Array(UserID)

    # Adds a user to the database
    abstract def add_user(id : UserID, username : String?, realname : String, rank : Int32) : User?

    # Updates a user with new data
    abstract def update_user(user : User) : Nil

    # Returns true if there are no users in the database
    # False otherwise
    abstract def no_users? : Bool?

    # Queries the database for users with warnings and removes a warning
    #
    # If the user still has warnings, the next time a warning is removed should
    # be the current time plus the value of *warn_lifespan*
    #
    # This should be invoked as a recurring task
    abstract def expire_warnings(warn_lifespan : Time::Span) : Nil

    # Sets the MOTD/rules to the given string
    abstract def set_motd(text : String) : Nil

    # Gets the MOTD/rules, if they exist
    abstract def motd : String?
  end
end
