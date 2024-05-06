require "../spec_helper.cr"

module PrivateParlorXT
  class MockHandler < Handler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  describe MockHandler do
    describe "#update_user_activity" do
      it "updates user activity time" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        previous_activity_time = user.last_active

        handler.update_user_activity(user, services)

        unless updated_user = services.database.get_user(80300)
          fail("Updated user should not be nil")
        end

        updated_user.last_active.should(be > previous_activity_time)
      end
    end

    describe "get_reply_message" do
      it "returns reply message if it exists" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_to = handler.get_reply_message(user, message, services)

        reply_to.should(eq(reply_to))
      end

      it "returns nil and queues 'no_reply' response if reply message does not exist" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        no_reply_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_to = handler.get_reply_message(user, no_reply_message, services)

        reply_to.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.no_reply))
      end
    end

    describe "get_reply_user" do
      it "returns reply user if message is in cache and user exists in database" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(user, reply_to, services)
          fail("Reply user should not be nil")
        end

        reply_user.id.should(eq(20000))
      end

      it "returns nil and queues not in cache response if message is not in cache" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        fake_message = create_message(
          50,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.get_reply_user(user, fake_message, services)

        reply_user.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns nil and queues not in cache response if reply user does not exist in database" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        services.history.new_message(12345, 50)
        services.history.add_to_history(50, 51, 80300)

        no_user_message = create_message(
          51,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.get_reply_user(user, no_user_message, services)

        reply_user.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end
    end
  end
end
