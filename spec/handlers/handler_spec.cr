require "../spec_helper.cr"

module PrivateParlorXT
  describe MockHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = MockHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#update_user_activity" do
      it "updates user activity time" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        previous_activity_time = beispiel.last_active

        handler.update_user_activity(beispiel, services)

        unless beispiel = services.database.get_user(80300)
          fail("Updated user should not be nil")
        end

        beispiel.last_active.should(be > previous_activity_time)
      end
    end

    describe "get_reply_message" do
      it "returns reply message if it exists" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        new_reply_to = handler.get_reply_message(beispiel, message, services)

        new_reply_to.should(eq(reply_to))
      end

      it "returns nil if reply message does not exist" do
        temp = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        new_reply_to = handler.get_reply_message(beispiel, temp, services)

        new_reply_to.should(be_nil)
      end
    end

    describe "get_reply_user" do
      it "returns reply user if message is in cache and user exists in database" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.get_reply_user(beispiel, reply_to, services)
          fail("Reply user should not be nil")
        end

        reply_user.id.should(eq(20000))
      end

      it "returns nil if message is not in cache" do
        fake_message = create_message(
          50,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.get_reply_user(beispiel, fake_message, services)

        reply_user.should(be_nil)
      end

      it "returns nil if reply user does not exist in database" do
        services.history.new_message(12345, 50)
        services.history.add_to_history(50, 51, 80300)

        no_user_message = create_message(
          51,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.get_reply_user(beispiel, no_user_message, services)

        reply_user.should(be_nil)

        services.history.delete_message_group(50)
      end
    end
  end
end