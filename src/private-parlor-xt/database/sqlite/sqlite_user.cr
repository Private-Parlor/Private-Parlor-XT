require "../../user.cr"
require "../../constants.cr"
require "db"

module PrivateParlorXT
  class SQLiteUser < User
    DB.mapping({
      id: {
        type: UserID,
        key: "id",
      },
      username: {
        type: String?,
        key: "username",
      },
      realname: {
        type: String,
        key: "realname",
      },
      rank: {
        type: Int32,
        key: "rank",
      },
      joined: {
        type: Time,
        key: "joined",
      },
      left: {
        type: Time?,
        key: "left",
      },
      last_active: {
        type: Time,
        key: "lastActive",
      },
      cooldown_until: {
        type: Time?,
        key: "cooldownUntil",
      },
      blacklist_reason: {
        type: String?,
        key: "blacklistReason",
      },
      warnings: {
        type: Int32,
        key: "warnings",
      },
      warn_expiry: {
        type: Time?,
        key: "warnExpiry",
      },
      karma: {
        type: Int32,
        key: "karma",
      },
      hide_karma: {
        type: Bool?,
        key: "hideKarma",
      },
      debug_enabled: {
        type: Bool?,
        key: "debugEnabled",
      },
      tripcode: {
        type: String?,
        key: "tripcode",
      },
    })

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


    
    # getter id : Int64

    # getter username : String?
    # getter realname : String
    # getter rank : Int32
    # getter joined : Time
    # getter left : Time?
    # @[DB::Field(key: "lastActive")]
    # getter last_active : Time
    # @[DB::Field(key: "cooldownUntil")]
    # getter cooldown_until : Time?
    # @[DB::Field(key: "blacklistReason")]
    # getter blacklist_reason : String?
    # getter warnings : Int32
    # @[DB::Field(key: "warnExpiry")]
    # getter warn_expiry : Time?
    # getter karma : Int32
    # @[DB::Field(key: "hideKarma")]
    # getter hide_karma : Bool?
    # @[DB::Field(key: "debugEnabled")]
    # getter debug_enabled : Bool?
    # getter tripcode : String?

  end
end