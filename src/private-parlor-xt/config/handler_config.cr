require "./config.cr"

module PrivateParlorXT
  # Contains a limited set of configuration variables that are needed for handlers
  class HandlerConfig
    getter blacklist_contact : String? = nil
    getter upvote_limit_interval : Int32 = 0
    getter downvote_limit_interval : Int32 = 0
    getter entity_types : Array(String) = ["bold", "italic", "text_link"]
    getter linked_network : Hash(String, String) = {} of String => String
    getter allow_spoilers : Bool? = false
    getter media_limit_period : Time::Span = 0.hours

    def initialize(config : Config)
      @blacklist_contact = config.blacklist_contact
      @upvote_limit_interval = config.upvote_limit_interval
      @downvote_limit_interval = config.downvote_limit_interval
      @entity_types = config.entities
      @linked_network = config.linked_network
      @allow_spoilers = config.media_spoilers
      @media_limit_period = config.media_limit_period.hours
    end
  end
end