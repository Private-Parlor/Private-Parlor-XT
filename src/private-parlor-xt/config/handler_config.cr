require "./config.cr"

module PrivateParlorXT
  # Contains a limited set of configuration variables that are needed for handlers
  class HandlerConfig
    getter blacklist_contact : String? = nil
    getter upvote_limit_interval : Int32 = 0
    getter downvote_limit_interval : Int32 = 0

    def initialize(config : Config)
      blacklist_contact = config.blacklist_contact
      upvote_limit_interval = config.upvote_limit_interval
      downvote_limit_interval = config.downvote_limit_interval
    end
  end
end