require "../../spec_helper.cr"

module PrivateParlorXT
  describe VenueHandler do

    client = MockClient.new

    services = create_services(client: client)

    handler = VenueHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#is_spamming?" do
      it "returns true if user is spamming venues" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end
        
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        ctx = create_context(client, create_update(11, message))
        spam_services = create_services(
          client: client, 
          spam: SpamHandler.new(spam_limit: 10, score_venue: 6)
        )

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.is_spamming?(beispiel, message, spam_services)

        unless score = spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.is_spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not spamming venues" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new())

        handler.is_spamming?(beispiel, message, spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spamless_services = create_services(client: client)

        handler.is_spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end
  end
end