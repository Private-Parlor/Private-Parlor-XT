require "../../spec_helper.cr"

module PrivateParlorXT
  describe VenueHandler do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set(CommandPermissions).new,
        Set{
          MessagePermissions::Venue,
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

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
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

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
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
        messages[0].data.should_not(eq("Somewhere St."))
      end

      it "returns early with 'insufficient karma' response if KarmaHandler is enabled and user does not have sufficient karma" do
        services = create_services(
          ranks: ranks,
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_venue: 10,
          ),
        )

        handler = VenueHandler.new(MockConfig.new)

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
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.insufficient_karma, {
          "amount" => 10.to_s,
          "type"   => "venue",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "returns early with 'spamming' response if user is spamming" do
        services = create_services(
          ranks: ranks,
          spam: SpamHandler.new(
            spam_limit: 10, score_venue: 6
          ),
        )

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
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
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
        )

        handler.do(spammy_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.spamming))
      end

      it "returns early if message has no venue" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

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

      it "returns early with 'not in cache' response if reply message does not exist in message history" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 50,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "records message statistics when statitics is enabled" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          ranks: ranks,
          database: database,
          statistics: SQLiteStatistics.new(connection),
        )

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
        )

        handler.do(message, services)

        unless stats = services.stats
          fail("Services should have a statistics object")
        end

        result = stats.message_counts

        result[Statistics::Messages::Venues].should(eq(1))
        result[Statistics::Messages::TotalMessages].should(eq(1))
      end

      it "spends user karma when KarmaHandler is enabled" do
        services = create_services(
          ranks: ranks,
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_venue: 10,
          )
        )

        handler = VenueHandler.new(MockConfig.new)

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
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
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

        handler = VenueHandler.new(MockConfig.new)

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
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "queues venue message" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Somewhere St."))
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

      it "queues venue with reply" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          venue: Tourmaline::Venue.new(
            location: Tourmaline::Location.new(longitude: 0.0, latitude: 0.0),
            title: "Venue",
            address: "Somewhere St.",
          ),
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        replies = {
          20000 => 5,
          80300 => 6,
          60200 => 7,
          50000 => nil,
        }

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Somewhere St."))

          if reply = msg.reply
            reply.message_id.should(eq(replies[msg.receiver]))
          else
            msg.receiver.should(eq(50000))
          end

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
      it "returns true if user is spamming venues" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

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
          spam: SpamHandler.new(spam_limit: 10, score_venue: 6)
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

      it "returns false if user is not spamming venues" do
        services = create_services(ranks: ranks)

        handler = VenueHandler.new(MockConfig.new)

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

        handler = VenueHandler.new(MockConfig.new)

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

        handler = VenueHandler.new(MockConfig.new)

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

      it "returns true if price for venue messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_venue: -10))

        handler = VenueHandler.new(MockConfig.new)

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
          karma_venue: 10,
        ))

        handler = VenueHandler.new(MockConfig.new)

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
          karma_venue: 10,
        ))

        handler = VenueHandler.new(MockConfig.new)

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
            karma_venue: 10,
          )
        )

        handler = VenueHandler.new(MockConfig.new)

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
          "type"   => "venue",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end

    describe "#spend_karma" do
      it "returns unaltered user if there is no karma economy handler" do
        services = create_services()

        handler = VenueHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if price of venue messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_venue: -10))

        handler = VenueHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_venue: 10,
        ))

        handler = VenueHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(10))
      end

      it "returns user with decremented karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_venue: 10,
        ))

        handler = VenueHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        result = handler.spend_karma(user, services)

        result.karma.should(eq(0))
      end
    end
  end
end
