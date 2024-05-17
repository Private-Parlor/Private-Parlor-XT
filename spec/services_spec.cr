require "./spec_helper"

module PrivateParlorXT
  describe Services do
    describe "#initialize" do
      it "initializes services with required objects" do
        config = MockConfig.new(
          database_history: false,
          spam_interval: 0,
          spam_handler: SpamHandler.new(),
          toggle_r9k_text: false,
          toggle_r9k_media: false,
          toggle_r9k_forwards: false,
          karma_economy: nil,
          statistics: false,
        )

        client = MockClient.new

        services = Services.new(config, client)
        services.config.should(be_a(HandlerConfig))
        services.locale.should(be_a(Locale))
        services.replies.should(be_a(Replies))
        services.logs.should(be_a(Logs))
        services.command_descriptions.should(be_a(CommandDescriptions))
        services.history.should(be_a(History))
        services.access.should(be_a(AuthorizedRanks))
        services.relay.should(be_a(Relay))
        services.spam.should(be_nil)
        services.robot9000.should(be_nil)
        services.karma.should(be_nil)
        services.stats.should(be_nil)
      end

      it "initializes optional modules" do
        config = MockConfig.new(
          database_history: true,
          spam_interval: 10,
          spam_handler: SpamHandler.new(),
          toggle_r9k_text: true,
          toggle_r9k_media: true,
          toggle_r9k_forwards: false,
          karma_economy: KarmaHandler.new(),
          statistics: true,
        )

        client = MockClient.new

        services = Services.new(config, client)
        services.config.should(be_a(HandlerConfig))
        services.locale.should(be_a(Locale))
        services.replies.should(be_a(Replies))
        services.logs.should(be_a(Logs))
        services.command_descriptions.should(be_a(CommandDescriptions))
        services.history.should(be_a(SQLiteHistory))
        services.access.should(be_a(AuthorizedRanks))
        services.relay.should(be_a(Relay))
        services.spam.should(be_a(SpamHandler))
        services.robot9000.should(be_a(Robot9000))
        services.karma.should(be_a(KarmaHandler))
        services.stats.should(be_a(SQLiteStatistics))
      end
    end
  end
end