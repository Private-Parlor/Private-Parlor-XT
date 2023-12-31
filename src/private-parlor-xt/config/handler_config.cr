require "./config.cr"

module PrivateParlorXT
  # Contains a limited set of configuration variables that are needed for handlers
  class HandlerConfig
    getter blacklist_contact : String? = nil
    getter sign_limit_interval : Int32 = 600
    getter upvote_limit_interval : Int32 = 0
    getter downvote_limit_interval : Int32 = 0
    getter entity_types : Array(String) = ["bold", "italic", "text_link"]
    getter linked_network : Hash(String, String) = {} of String => String
    getter allow_spoilers : Bool? = false
    getter media_limit_period : Time::Span = 0.hours
    getter karma_levels : Hash(Int32, String) = {} of Int32 => String
    getter default_rank : Int32 = 0
    getter tripcode_salt : String = ""
    getter cooldown_base : Int32 = 5
    getter warn_lifespan : Int32 = 7 * 24
    getter warn_deduction : Int32 = 10
    getter registration_open : Bool? = true
    getter pseudonymous : Bool? = false
    getter flag_signatures : Bool? = false

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
    end
  end
end
