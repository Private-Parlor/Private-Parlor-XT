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

    describe "#reply_message" do
      it "returns reply message if it exists" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 6,
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
          reply_to_message: reply,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_to = handler.reply_message(user, message, services)

        reply_to.should(eq(reply))
      end

      it "returns nil and queues 'no_reply' response if reply message does not exist" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        no_reply_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply = handler.reply_message(user, no_reply_message, services)

        reply.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.no_reply))
      end
    end

    describe "#reply_user" do
      it "returns reply user if message is in cache and user exists in database" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        unless reply_user = handler.reply_user(user, reply, services)
          fail("Reply user should not be nil")
        end

        reply_user.id.should(eq(20000))
      end

      it "returns nil and queues not in cache response if message is not in cache" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        fake_message = Tourmaline::Message.new(
          message_id: 50,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.reply_user(user, fake_message, services)

        reply_user.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns nil and queues not in cache response if reply user does not exist in database" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        services.history.new_message(12345, 50)
        services.history.add_to_history(50, 51, 80300)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        no_user_message = Tourmaline::Message.new(
          message_id: 51,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user = handler.reply_user(user, no_user_message, services)

        reply_user.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end
    end

    describe "#unique?" do
      it "returns true if Services does not have an Robot9000 object" do
        services = create_services()

        handler = MockHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        handler.unique?(user, message, services).should(be_true)

        handler.unique?(user, message, services).should(be_true)
      end

      it "returns true if the message is unique" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        handler = MockHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        handler.unique?(user, message, services).should(be_true)
      end

      it "returns false if the message is not unique" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        handler = MockHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        handler.unique?(user, message, services).should(be_true)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "Example    text.",
        )

        handler.unique?(user, message, services).should(be_false)
      end
    end
  end
end
