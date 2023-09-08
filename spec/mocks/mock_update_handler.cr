require "../spec_helper.cr"

module PrivateParlorXT
  # Using NewChatMembers update as it's least likely to be used
  @[On(update: Tourmaline::UpdateAction::NewChatMembers)]
  class MockUpdateHandler < UpdateHandler
    def do(update : Tourmaline::Context)
    end
  end
end
