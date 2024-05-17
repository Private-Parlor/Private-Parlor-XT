require "../../spec_helper.cr"

module PrivateParlorXT
  describe PollHandler do
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

    describe "#do" do
      it "returns early if message is a forward" do
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
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
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
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
        messages[0].data.should_not(eq("poll_item_one"))
      end

      it "returns early with 'insufficient karma' response if KarmaHandler is enabled and user does not have sufficient karma" do
        services = create_services(
          ranks: ranks,
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_poll: 10,
          ),
        )

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.insufficient_karma, {
          "amount" => 10.to_s,
          "type"   => "poll",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "returns early with 'spamming' response if user is spamming" do
        services = create_services(
          ranks: ranks,
          spam: SpamHandler.new(
            spam_limit: 10, score_poll: 6
          ),
        )

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        spammy_message = Tourmaline::Message.new(
          message_id: 20,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(spammy_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.spamming))
      end

      it "returns early if message has no poll" do
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "records message statistics when statitics is enabled" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          ranks: ranks,
          database: database,
          statistics: SQLiteStatistics.new(connection),
        )

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        unless stats = services.stats
          fail("Services should have a statistics object")
        end

        result = stats.message_counts

        result[Statistics::Messages::Polls].should(eq(1))
        result[Statistics::Messages::TotalMessages].should(eq(1))
      end

      it "spends user karma when KarmaHandler is enabled" do
        services = create_services(
          ranks: ranks,
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_poll: 10,
          ),
        )

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))
        user.increment_karma(30)
        services.database.update_user(user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        updated_user.karma.should(eq(0))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "queues poll" do
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          poll: Tourmaline::Poll.new(
            id: "poll_item_one",
            question: "Poll Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          ),
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("12"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        spam_services = create_services(
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
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        spam_services = create_services(spam: SpamHandler.new)

        handler.spamming?(beispiel, message, spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        services = create_services(ranks: ranks)

        handler = PollHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end

    describe "#sufficient_karma?" do
      it "returns true if there is no karma economy handler" do
        services = create_services()

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if price for polls is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_poll: -10))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_poll: 10,
        ))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user has sufficient karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_poll: 10,
        ))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns nil and queues 'insufficient karma' response if user does not have enough karma" do
        services = create_services(
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_poll: 10,
          )
        )

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 9)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_nil)

        expected = Format.substitute_reply(services.replies.insufficient_karma, {
          "amount" => 10.to_s,
          "type"   => "poll",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end

    describe "#spend_karma" do
      it "returns unaltered user if there is no karma economy handler" do
        services = create_services()

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if price of polls is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_poll: -10))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_poll: 10,
        ))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns user with decremented karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_poll: 10,
        ))

        handler = PollHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(0))
      end
    end
  end
end
