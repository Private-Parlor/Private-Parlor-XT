require "../spec_helper.cr"

module PrivateParlorXT
  @[RespondsTo(command: "mock_test", config: "enable_mock_test")]
  class MockCommandHandler < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
    end
  end
end
