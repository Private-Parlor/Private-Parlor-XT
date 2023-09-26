require "./spec_helper"

module PrivateParlorXT
  VERSION = "spec"

  describe PrivateParlorXT do
    config = MockConfig.new
    client = MockClient.new
    relay = Relay.new("", client)
    access = AuthorizedRanks.new(config.ranks)
    localization = Localization.parse_locale(Path["#{__DIR__}/../locales/"], "en-US")
    database = SQLiteDatabase.new(DB.open("sqlite3://%3Amemory%3A"))
    history = CachedHistory.new(config.message_lifespan.hours)

    services = Services.new(
      HandlerConfig.new(config),
      localization.locale,
      localization.replies,
      localization.logs,
      localization.command_descriptions,
      database,
      history,
      access,
      relay,
    )

    it "generates command handlers" do
      arr = PrivateParlorXT.generate_command_handlers(config, services)

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
      PrivateParlorXT.generate_update_handlers(config, client, services)

      registered_actions = client.dispatcher.event_handlers.keys

      registered_actions.should(contain(Tourmaline::UpdateAction::NewChatMembers))
    end
  end
end
