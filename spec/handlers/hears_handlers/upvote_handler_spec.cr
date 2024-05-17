require "../../spec_helper.cr"

module PrivateParlorXT
  describe UpvoteHandler do
    describe "#do" do
      it "returns early if user's rank cannot upvote" do
        services = create_services(
          ranks: {
            10 => Rank.new(
              "Mod",
              Set(CommandPermissions).new,
              Set(MessagePermissions).new,
            ),
          },
        )

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 50,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.fail))
      end

      it "returns early with 'no reply' if user upvoted without a reply" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.no_reply))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 50,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns early with 'spamming' response if user is spamming upvotes" do
        services = create_services(
          spam: SpamHandler.new,
        )

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        second_reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        spammy_message = Tourmaline::Message.new(
          message_id: 14,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: second_reply,
          from: tourmaline_user
        )

        handler.do(spammy_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.upvote_spam))
      end

      it "returns early if user already upvoted the message or attempted to upvote his own message" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        # Attempt to upvote the same message again
        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.already_voted))

        second_reply = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        upvote_own_message = Tourmaline::Message.new(
          message_id: 14,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: second_reply,
          from: tourmaline_user
        )

        handler.do(upvote_own_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.upvoted_own_message))
      end

      it "updates user activity" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "records message statistics" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          database: database,
          statistics: SQLiteStatistics.new(connection),
        )

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        unless stats = services.stats
          fail("Services should have a statistics object")
        end

        result = stats.karma_counts

        result[Statistics::Karma::TotalUpvotes].should(eq(1))
      end

      it "increments reply user's karma and sends upvote replies" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless user_to_upvote = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 80300 should exist in the database")
        end

        updated_user.karma.should(eq(user_to_upvote.karma + 1))

        gave_upvote_expected = Format.substitute_reply(services.replies.gave_upvote)
        got_upvote_expected = Format.substitute_reply(services.replies.got_upvote)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        messages.each do |msg|
          msg.origin.should(be_nil)
          msg.sender.should(be_nil)

          [80300, 20000].should(contain(msg.receiver))

          if msg.receiver == 80300
            msg.data.should(eq(gave_upvote_expected))
          end

          if msg.receiver == 20000
            msg.data.should(eq(got_upvote_expected))
          end
        end
      end
    end

    describe "#user_from_message" do
      it "returns user" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
          reply_to_message: reply,
        )

        unless returned_user = handler.user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username")

        new_names_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "+1",
        )

        unless returned_user = handler.user_from_message(new_names_message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns nil if message has no sender" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: nil,
        )

        handler.user_from_message(message, services).should(be_nil)
      end

      it "returns nil if user does not exist" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)

        bot_user = Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        user = handler.user_from_message(message, services)

        user.should(be_nil)
      end

      it "queues not in chat message if user does not exist" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        bot_user = Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.user_from_message(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "queues 'blacklisted' response if user is blacklisted" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(70000, false, "BLACKLISTED")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.user_from_message(message, services)

        expected = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end

    describe "#authorized?" do
      it "returns true if user can upvote" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "+1",
        )

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        handler.authorized?(beispiel, message, :Upvote, services).should(be_true)
      end

      it "returns false if user can't upvote" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "+1",
        )

        unauthorized_user = MockUser.new(9000, rank: -10)

        handler.authorized?(unauthorized_user, message, :Upvote, services).should(be_false)
      end
    end

    describe "#spamming?" do
      it "returns true if user is upvote spamming" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
        )

        spam_services = create_services(spam: SpamHandler.new)

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services)

        unless spam.upvote_last_used[beispiel.id]?
          fail("Expiration time should not be nil")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not upvote spamming" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
        )

        spam_services = create_services(spam: SpamHandler.new)

        handler.spamming?(beispiel, message, spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end

    describe "#upvote_message" do
      it "returns true if upvoted successfully" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

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
          text: "+1",
          reply_to_message: reply,
        )

        unless reply_user = handler.reply_user(user, reply, services)
          fail("User 20000 should exist in the database")
        end

        previous_karma = reply_user.karma

        handler.upvote_message(user, reply_user, message, reply, services).should(be_true)

        unless updated_user = services.database.get_user(reply_user.id)
          fail("User 20000 should exist in the database")
        end

        updated_user.karma.should(be > previous_karma)
      end

      it "returns false if user attempts to upvote own message" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_message = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "+1",
          reply_to_message: reply_message,
        )

        unless reply_user = handler.reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.upvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end

      it "returns false if user already upvoted the message" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_message = Tourmaline::Message.new(
          message_id: 2,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        tourmaline_user = Tourmaline::User.new(60200, false, "voorbeeld")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "+1",
          reply_to_message: reply_message,
        )

        unless user = services.database.get_user(60200)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.upvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end
    end

    describe "#record_message_statistics" do
      it "updates the number of upvotes" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          database: database,
          statistics: SQLiteStatistics.new(connection),
        )

        handler = UpvoteHandler.new(MockConfig.new)

        handler.record_message_statistics(services)

        unless stats = services.stats
          fail("Services should have a statistics object")
        end

        result = stats.karma_counts

        result[Statistics::Karma::TotalUpvotes].should(eq(1))
      end
    end

    describe "#send_replies" do
      it "sends reply messages to invoker and receiver" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
          reply_to_message: reply,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply, services)
          fail("User 20000 should exist in the database")
        end

        reply_user.increment_karma

        handler.send_replies(user, reply_user, message, reply, services)

        gave_upvote_expected = Format.substitute_reply(services.replies.gave_upvote)
        got_upvote_expected = Format.substitute_reply(services.replies.got_upvote)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        messages.each do |msg|
          msg.origin.should(be_nil)
          msg.sender.should(be_nil)

          [80300, 20000].should(contain(msg.receiver))

          if msg.receiver == 80300
            msg.data.should(eq(gave_upvote_expected))
          end

          if msg.receiver == 20000
            msg.data.should(eq(got_upvote_expected))
          end
        end
      end

      it "does not send got upvote message if receiver has disabled notifications" do
        services = create_services()

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
          reply_to_message: reply,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply, services)
          fail("User 20000 should exist in the database")
        end

        reply_user.toggle_karma

        handler.send_replies(user, reply_user, message, reply, services)

        gave_upvote_expected = Format.substitute_reply(services.replies.gave_upvote)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].origin.should(be_nil)
        messages[0].sender.should(be_nil)
        messages[0].receiver.should(eq(80300))
        messages[0].data.should(eq(gave_upvote_expected))
      end

      it "queues 'leveled up' response as well when reply user gains a level" do
        services = create_services(
          config: HandlerConfig.new(MockConfig.new(karma_levels: {
            (Int32::MIN...0) => "Junk",
            (0...10)         => "Normal",
            (10...20)        => "Common",
            (20...30)        => "Uncommon",
            (30...40)        => "Rare",
            (40...50)        => "Legendary",
            (50..Int32::MAX) => "Unique",
          }))
        )

        handler = UpvoteHandler.new(MockConfig.new)

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
          text: "+1",
          reply_to_message: reply,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply, services)
          fail("User 20000 should exist in the database")
        end

        reply_user.karma.should(eq(0))

        reply_user.increment_karma(10)

        handler.send_replies(user, reply_user, message, reply, services)

        gave_upvote_expected = Format.substitute_reply(services.replies.gave_upvote)
        got_upvote_expected = Format.substitute_reply(services.replies.got_upvote)
        level_up_expected = Format.substitute_message(services.replies.karma_level_up, {
          "level" => "Common",
        })

        reply_user_responses = [got_upvote_expected, level_up_expected]

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(3))

        messages.each do |msg|
          msg.origin.should(be_nil)
          msg.sender.should(be_nil)

          [80300, 20000].should(contain(msg.receiver))

          if msg.receiver == 80300
            msg.data.should(eq(gave_upvote_expected))
          end

          if msg.receiver == 20000
            msg.data.in?(reply_user_responses).should(be_true)
          end
        end
      end

      it "sends reply messages with reasons" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              karma_reasons: true,
            )
          )
        )

        handler = UpvoteHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        reason = "good post!"

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
          text: "+1 #{reason}",
          reply_to_message: reply,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply, services)
          fail("User 20000 should exist in the database")
        end

        reply_user.increment_karma

        handler.send_replies(user, reply_user, message, reply, services)

        gave_upvote_expected = handler.karma_reason(reason, services.replies.gave_upvote, services)

        got_upvote_expected = handler.karma_reason(reason, services.replies.got_upvote, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        messages.each do |msg|
          msg.origin.should(be_nil)
          msg.sender.should(be_nil)

          [80300, 20000].should(contain(msg.receiver))

          if msg.receiver == 80300
            msg.data.should(eq(gave_upvote_expected))
          end

          if msg.receiver == 20000
            msg.data.should(eq(got_upvote_expected))
          end
        end
      end
    end

    describe "#karma_level_up" do
      it "returns early if there are no karma levels" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String)
          )
        )

        handler = UpvoteHandler.new(MockConfig.new)

        reply_user = MockUser.new(9000, karma: 30)

        handler.karma_level_up(reply_user, ReplyParameters.new(6, 9000), services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "returns early if reply user has not leveled up" do
        services = create_services(
          config: HandlerConfig.new(MockConfig.new(karma_levels: {
            (Int32::MIN...0) => "Junk",
            (0...10)         => "Normal",
            (10...20)        => "Common",
            (20...30)        => "Uncommon",
            (30...40)        => "Rare",
            (40...50)        => "Legendary",
            (50..Int32::MAX) => "Unique",
          }))
        )

        handler = UpvoteHandler.new(MockConfig.new)

        reply_user = MockUser.new(9000, karma: 29)

        handler.karma_level_up(reply_user, ReplyParameters.new(6, 9000), services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "queues 'leveled up' response when reply user has gained a level" do
        services = create_services(
          config: HandlerConfig.new(MockConfig.new(karma_levels: {
            (Int32::MIN...0) => "Junk",
            (0...10)         => "Normal",
            (10...20)        => "Common",
            (20...30)        => "Uncommon",
            (30...40)        => "Rare",
            (40...50)        => "Legendary",
            (50..Int32::MAX) => "Unique",
          }))
        )

        handler = UpvoteHandler.new(MockConfig.new)

        reply_user = MockUser.new(9000, karma: 30)

        handler.karma_level_up(reply_user, ReplyParameters.new(6, 9000), services)

        expected = Format.substitute_reply(services.replies.karma_level_up, {
          "level" => "Rare",
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].receiver.should(eq(9000))
        messages[0].data.should(eq(expected))
      end
    end
  end
end
