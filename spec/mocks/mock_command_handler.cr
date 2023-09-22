require "../spec_helper.cr"

module PrivateParlorXT
  @[RespondsTo(command: "mock_test", config: "enable_mock_test")]
  class MockCommandHandler < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
    end
  end
end
