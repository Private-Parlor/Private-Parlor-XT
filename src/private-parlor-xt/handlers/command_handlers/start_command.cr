require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[RespondsTo(command: "start", config: "enable_start")]
  class StartCommand < CommandHandler

    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      raise NotImplementedError.new("StartCommand has not been implemented yet")
    end
  end
end