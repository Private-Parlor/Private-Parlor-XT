require "../spec_helper.cr"

module PrivateParlorXT
  # Using NewChatMembers update as it's least likely to be used
  @[On(update: Tourmaline::UpdateAction::NewChatMembers, config: "relay_new_chat_members")]
  class MockUpdateHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
    end
  end
end
