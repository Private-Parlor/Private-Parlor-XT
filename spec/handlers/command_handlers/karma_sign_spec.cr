require "../../spec_helper.cr"

module PrivateParlorXT
  describe KarmaSignCommand do
    client = MockClient.new

    services = create_services(relay: MockRelay.new("", client))

    handler = KarmaSignCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "updates message contents" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/ksign   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              6
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              9,
              7
            ),
          ]
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        expected_text = "Example text t. Normal"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(2))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(13))
        updated_message.entities[0].length.should(eq(9))

        updated_message.entities[1].type.should(eq("italic"))
        updated_message.entities[1].offset.should(eq(13))
        updated_message.entities[1].length.should(eq(9))
      end
    end

    describe "#spamming?" do
      it "returns true if user is sign spamming" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ksign Example",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, "", spam_services)

        unless spam.sign_last_used[beispiel.id]?
          fail("Expiration time should not be nil")
        end

        handler.spamming?(beispiel, message, "", spam_services).should(be_true)
      end

      it "returns true if user is spamming text" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ksign Example",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new(
          spam_limit: 10,
          score_character: 1,
          score_line: 0,
        ))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, "Example", spam_services)

        unless spam.scores[beispiel.id]?
          fail("Score should not be nil")
        end

        handler.spamming?(beispiel, message, "Example", spam_services).should(be_true)
      end

      it "returns false if user is not sign spamming" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ksign Example",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        handler.spamming?(beispiel, message, "", spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ksign Example",
        )

        spamless_services = create_services(client: client)

        handler.spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end

    describe "#get_karma_level" do
      it "returns karma level according to user's karma" do
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: -50),
        ).should(eq("Junk"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: -9),
        ).should(eq("Junk"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 5),
        ).should(eq("Normal"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 12),
        ).should(eq("Common"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 25),
        ).should(eq("Uncommon"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 39),
        ).should(eq("Rare"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 44),
        ).should(eq("Legendary"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 55),
        ).should(eq("Unique"))
      end
    end
  end
end
