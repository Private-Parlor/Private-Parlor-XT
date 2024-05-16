require "../user.cr"
require "../constants.cr"
require "db"

module PrivateParlorXT

  # An implementation of `User` for the the `SQLiteDatabase`
  class SQLiteUser < User
    DB.mapping({
      id: {
        type: UserID,
        key:  "id",
      },
      username: {
        type: String?,
        key:  "username",
      },
      realname: {
        type: String,
        key:  "realname",
      },
      rank: {
        type: Int32,
        key:  "rank",
      },
      joined: {
        type: Time,
        key:  "joined",
      },
      left: {
        type: Time?,
        key:  "left",
      },
      last_active: {
        type: Time,
        key:  "lastActive",
      },
      cooldown_until: {
        type: Time?,
        key:  "cooldownUntil",
      },
      blacklist_reason: {
        type: String?,
        key:  "blacklistReason",
      },
      warnings: {
        type: Int32,
        key:  "warnings",
      },
      warn_expiry: {
        type: Time?,
        key:  "warnExpiry",
      },
      karma: {
        type: Int32,
        key:  "karma",
      },
      hide_karma: {
        type: Bool?,
        key:  "hideKarma",
      },
      debug_enabled: {
        type: Bool?,
        key:  "debugEnabled",
      },
      tripcode: {
        type: String?,
        key:  "tripcode",
      },
    })

    # Creates an instance of `SQLiteUser`.
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
      super
    end
  end
end
