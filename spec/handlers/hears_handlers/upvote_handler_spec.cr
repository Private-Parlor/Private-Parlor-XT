require "../../spec_helper.cr"

module PrivateParlorXT
  describe UpvoteHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = UpvoteHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#get_message_and_user" do
      it "returns message and user" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
          reply_to_message: reply_to,
        )

        ctx = create_context(client, create_update(11, message))

        tuple = handler.get_message_and_user(ctx, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end
        unless returned_user = tuple[1]
          fail("Did not get a user from method")
        end

        returned_message.should(eq(message))

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        new_names_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username"),
          text: "+1",
        )

        new_names_context = create_context(client, create_update(11, new_names_message))

        tuple = handler.get_message_and_user(new_names_context, services)

        unless tuple[0]
          fail("Did not get a message from method")
        end
        unless returned_user = tuple[1]
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns message if user does not exist" do
        no_user_message = create_message(
          11,
          Tourmaline::User.new(9000, false, "no_user"),
          text: "+1",
        )

        no_user_context = create_context(client, create_update(11, no_user_message))

        tuple = handler.get_message_and_user(no_user_context, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(no_user_message))
      end

      it "returns message if user can't use a command (blacklisted)" do
        blacklisted_user_message = create_message(
          11,
          Tourmaline::User.new(70000, false, "BLACKLISTED"),
          text: "+1",
        )

        blacklisted_user_context = create_context(client, create_update(11, blacklisted_user_message))

        tuple = handler.get_message_and_user(blacklisted_user_context, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(blacklisted_user_message))
      end

      it "returns nil if message does not exist" do
        empty_context = create_context(client, create_update(11))

        tuple = handler.get_message_and_user(empty_context, services)

        tuple.should(eq({nil, nil}))
      end
    end

    describe "#authorized?" do
      it "returns true if user can upvote" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
        )

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        handler.authorized?(beispiel, message, :Upvote, services).should(be_true)
      end

      it "returns false if user can't upvote" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
        )

        unauthorized_user = SQLiteUser.new(9000, rank: -10)

        handler.authorized?(unauthorized_user, message, :Upvote, services).should(be_false)
      end
    end

    describe "#spamming?" do
      it "returns true if user is upvote spamming" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

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
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
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
          text: "+1",
        )

        spamless_services = create_services(client: client)

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end

    describe "#upvote_message" do
      it "returns true if upvoted successfully" do
        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
          reply_to_message: reply_to,
        )

        unless reply_user = handler.get_reply_user(user, reply_to, services)
          fail("User 20000 should exist in the database")
        end

        previous_karma = reply_user.karma

        handler.upvote_message(user, reply_user, message, reply_to, services).should(be_true)

        unless updated_user = services.database.get_user(reply_user.id)
          fail("User 20000 should exist in the database")
        end

        updated_user.karma.should(be > previous_karma)
      end

      it "returns false if user attempts to upvote own message" do
        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_message = create_message(
          1,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
          reply_to_message: reply_message,
        )

        unless reply_user = handler.get_reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.upvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end

      it "returns false if user already upvoted the message" do
        reply_message = create_message(
          2,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "+1",
          reply_to_message: reply_message,
        )

        unless user = services.database.get_user(60200)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.upvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end
    end
  end
end
