require "./config.cr"

module PrivateParlorXT
  # Contains a limited set of `Config` variables that are needed for handlers
  class HandlerConfig
    # Returns the contact string shown to blacklisted users
    getter blacklist_contact : String? = nil

    # Limit a users' usage of `SignCommand` and `TripodeSignCommand` for once every interval (in seconds)
    getter sign_limit_interval : Int32 = 600

    # Limit a user's usage of `UpvoteHandler` for once every interval (in seconds)
    getter upvote_limit_interval : Int32 = 0

    # Limit a user's usage of `DownvoteHandler` for once every interval (in seconds)
    getter downvote_limit_interval : Int32 = 0

    # An array of `String` referring to entity types that will be removed from all messages
    getter entity_types : Array(String) = ["bold", "italic", "text_link"]

    # A hash of `String` => `String` mapping the name of a chat to the chat's username
    getter linked_network : Hash(String, String) = {} of String => String

    # Whether or not to allow users to send photos, videos, or GIFs with a spoiler overlay
    getter allow_spoilers : Bool? = false

    # The duration (in hours) in which new users cannot send media
    getter media_limit_period : Time::Span = 0.hours

    # A hash of `Range(Int32, Int32)` => `String` mapping a range of possible `User` karma values to the name of the karma level that is defined by that range
    getter karma_levels : Hash(Range(Int32, Int32), String) = {} of Range(Int32, Int32) => String

    # The value of the `Rank` a user will be set to when joining for the first time or getting demoted
    getter default_rank : Int32 = 0

    # A `String` used to generate secure tripcodes
    getter tripcode_salt : String = ""

    # The base integer for which cooldown times are computed from
    getter cooldown_base : Int32 = 5

    # The length of time (in hours) until a warning expires
    getter warn_lifespan : Int32 = 7 * 24

    # The amount of karma to remove from a user when receiving a cooldown
    getter warn_deduction : Int32 = 10

    # Whether or not registration is open, allowing new users to join
    getter registration_open : Bool? = true

    # Whether or not to enable pseudonymous mode, which forces the use of tripcodes for all users and automatically prepends messages with the user's tripcode
    getter pseudonymous : Bool? = false

    # Whether or not to replace tripcodes with a flag or emoji signature
    getter flag_signatures : Bool? = false

    # Whether or not to allow users to attach a reason to their upvote/downvote messages
    getter karma_reasons : Bool? = false

    # Creates a new instance of `HandlerConfig``
    def initialize(config : Config)
      @blacklist_contact = config.blacklist_contact
      @sign_limit_interval = config.sign_limit_interval
      @upvote_limit_interval = config.upvote_limit_interval
      @downvote_limit_interval = config.downvote_limit_interval
      @entity_types = config.entities
      @linked_network = config.linked_network
      @allow_spoilers = config.media_spoilers
      @media_limit_period = config.media_limit_period.hours
      @karma_levels = config.karma_levels
      @default_rank = config.default_rank
      @tripcode_salt = config.salt
      @cooldown_base = config.cooldown_base
      @warn_lifespan = config.warn_lifespan
      @warn_deduction = config.warn_deduction
      @registration_open = config.registration_open
      @pseudonymous = config.pseudonymous
      @flag_signatures = config.flag_signatures
      @karma_reasons = config.karma_reasons
    end
  end
end
