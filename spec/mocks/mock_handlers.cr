require "../spec_helper.cr"

module PrivateParlorXT
  @[Hears(pattern: "mockpattern", config: "enable_mockpattern", command: true)]
  class MockHearsHandler < HearsHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  # Using NewChatMembers update as it's least likely to be used
  @[On(update: :NewChatMembers, config: "relay_new_chat_members")]
  class MockUpdateHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  @[RespondsTo(command: "mock_test", config: "enable_mock_test")]
  class MockCommandHandler < CommandHandler
    def initialize(config : Config)
    end

    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end
end
