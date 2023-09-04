require "./spec_helper"

describe PrivateParlorXT do

  it "generates command handlers" do
    arr = PrivateParlorXT.generate_command_handlers()

    contains_mock = false
    arr.each do |command|
      if command.commands.includes?("mock_test")
        contains_mock = true
      end
    end

    contains_mock.should(eq(true))
  end

  it "generates update handlers" do
    client = PrivateParlorXT::MockClient.new
    PrivateParlorXT.generate_update_handlers(client)

    registered_actions = client.dispatcher.event_handlers.keys

    registered_actions.should(contain(Tourmaline::UpdateAction::NewChatMembers))
  end
end
