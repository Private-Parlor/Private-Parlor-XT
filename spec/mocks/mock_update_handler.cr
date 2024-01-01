require "../spec_helper.cr"

module PrivateParlorXT
  # Using NewChatMembers update as it's least likely to be used
  @[On(update: :NewChatMembers, config: "relay_new_chat_members")]
  class MockUpdateHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(message : Tourmaline::Message, services : Services)
    end
  end
end
