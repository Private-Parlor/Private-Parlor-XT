require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[RespondsTo(command: "stop", config: "enable_stop")]
  class StopCommand < CommandHandler

    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      raise NotImplementedError.new("StopCommand has not been implemented yet")
    end
  end
end