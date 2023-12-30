require "../../spec_helper.cr"

module PrivateParlorXT
  describe PollHandler do
    client = MockClient.new

    ranks = {
      10 => Rank.new(
        "Mod",
        Set(CommandPermissions).new,
        Set{
          MessagePermissions::Poll,
        },
      ),
      -5 => Rank.new(
        "Restricted",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = PollHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if message is a forward" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          poll: Tourmaline::Poll.new(
            "poll_item_one",
            "Poll Question",
            0,
            false,
            true,
            "regular",
            false,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "returns early if user is not authorized" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          poll: Tourmaline::Poll.new(
            "poll_item_one",
            "Poll Question",
            0,
            false,
            true,
            "regular",
            false,
          ),
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(-5)
        services.database.update_user(user)

        

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should_not(eq("voice_item_one"))
      end

      it "queues poll" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          poll: Tourmaline::Poll.new(
            "poll_item_one",
            "Poll Question",
            0,
            false,
            true,
            "regular",
            false,
          ),
        )

        

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("12"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end
    end

    describe "#spamming?" do
      it "returns true if user is spamming polls" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(
          client: client,
          spam: SpamHandler.new(spam_limit: 10, score_poll: 6)
        )

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services)

        unless spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not spamming polls" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        handler.spamming?(beispiel, message, spam_services).should(be_false)
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

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end
  end
end
