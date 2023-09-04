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

  end
end