require "./spec_helper"

module PrivateParlorXT
  describe PrivateParlorXT do
    config = MockConfig.new
    client = MockClient.new
    relay = Relay.instance("", client)
    access = MockAuthorizedRanks.new(config)
    locale = Locale.parse_locale(Path["#{__DIR__}/../locales/"], "en-US")
    database = instantiate_sqlite_database
    history = MockCachedHistory.new(config)

    around_each do |example|
      create_sqlite_database
      example.run
      delete_sqlite_database
    end

    it "generates command handlers" do
      arr = PrivateParlorXT.generate_command_handlers(config, relay, access, database, history, locale)

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
      PrivateParlorXT.generate_update_handlers(client, config, relay, access, database, history, locale, nil)

      registered_actions = client.dispatcher.event_handlers.keys

      registered_actions.should(contain(Tourmaline::UpdateAction::NewChatMembers))
    end
  end
end
