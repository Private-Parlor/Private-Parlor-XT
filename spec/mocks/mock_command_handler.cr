require "../spec_helper.cr"

module PrivateParlorXT
  @[RespondsTo(command: "mock_test", config: "enable_mock_test")]
  class MockCommandHandler < CommandHandler
    def initialize(config : Config)
    end

    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end
end
