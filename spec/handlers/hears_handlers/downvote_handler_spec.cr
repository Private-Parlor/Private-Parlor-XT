require "../../spec_helper.cr"

module PrivateParlorXT
  describe DownvoteHandler do
    client = MockClient.new

    services = create_services(relay: MockRelay.new("", client))

    handler = DownvoteHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(relay: MockRelay.new("", client))

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#get_user_from_message" do
      it "returns user" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
          reply_to_message: reply_to,
        )

        unless returned_user = handler.get_user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        new_names_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username"),
          text: "-1",
        )

        unless returned_user = handler.get_user_from_message(new_names_message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns nil if user does not exist" do
        message = create_message(
          11,
          Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username"),
        )

        user = handler.get_user_from_message(message, services)

        user.should(be_nil)
      end

      it "queues not in chat message if user does not exist" do
        mock_services = create_services(relay: MockRelay.new("", client))

        message = create_message(
          11,
          Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username"),
        )

        handler.get_user_from_message(message, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(mock_services.replies.not_in_chat))
      end
    end

    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        mock_services = create_services(relay: MockRelay.new("", client))

        user = MockUser.new(9000, rank: -10)

        handler.deny_user(user, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(mock_services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end

    describe "#authorized?" do
      it "returns true if user can downvote" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
        )

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        handler.authorized?(beispiel, message, :Downvote, services).should(be_true)
      end

      it "returns false if user can't downvote" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
        )

        unauthorized_user = MockUser.new(9000, rank: -10)

        handler.authorized?(unauthorized_user, message, :Downvote, services).should(be_false)
      end
    end

    describe "#spamming?" do
      it "returns true if user is downvote spamming" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services)

        unless spam.downvote_last_used[beispiel.id]?
          fail("Expiration time should not be nil")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not downvote spamming" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
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
          text: "-1",
        )

        spamless_services = create_services(client: client)

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end
    end

    describe "#downvote_message" do
      it "returns true if downvoted successfully" do
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
          text: "-1",
          reply_to_message: reply_to,
        )

        unless reply_user = handler.get_reply_user(user, reply_to, services)
          fail("User 20000 should exist in the database")
        end

        previous_karma = reply_user.karma

        handler.downvote_message(user, reply_user, message, reply_to, services).should(be_true)

        unless updated_user = services.database.get_user(reply_user.id)
          fail("User 20000 should exist in the database")
        end

        updated_user.karma.should(be < previous_karma)
      end

      it "returns false if user attempts to downvote own message" do
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
          text: "-1",
          reply_to_message: reply_message,
        )

        unless reply_user = handler.get_reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.downvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end

      it "returns false if user already downvoted the message" do
        reply_message = create_message(
          2,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "-1",
          reply_to_message: reply_message,
        )

        unless user = services.database.get_user(60200)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(user, reply_message, services)
          fail("User 20000 should exist in the database")
        end

        handler.downvote_message(user, reply_user, message, reply_message, services).should(be_false)
      end
    end

    describe "#send_replies" do
      it "sends reply messages to invoker and receiver" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
          reply_to_message: reply_to,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(user, reply_to, services)
          fail("User 20000 should exist in the database")
        end

        handler.send_replies(user, reply_user, message, reply_to, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        messages.each do |msg|
          msg.origin_msid.should(be_nil)
          msg.sender.should(be_nil)

          [80300, 20000].should(contain(msg.receiver))

          if msg.receiver == 80300
            msg.data.should(eq(services.replies.gave_downvote))
          end

          if msg.receiver == 20000
            msg.data.should(eq(services.replies.got_downvote))
          end
        end
      end

      it "does not send got downvote message if receiver has disabled notifications" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
          reply_to_message: reply_to,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(user, reply_to, services)
          fail("User 20000 should exist in the database")
        end

        reply_user.toggle_karma

        handler.send_replies(user, reply_user, message, reply_to, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].origin_msid.should(be_nil)
        messages[0].sender.should(be_nil)
        messages[0].receiver.should(eq(80300))
        messages[0].data.should(eq(services.replies.gave_downvote))
      end
    end
  end
end
