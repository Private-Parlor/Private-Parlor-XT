require "../../spec_helper.cr"

module PrivateParlorXT
  describe PinCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Pin,
        },
        Set(MessagePermissions).new,
      ),
      0 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = PinCommand.new(MockConfig.new)

        generate_users(services.database)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        reply_to = create_message(
          message_id: 9,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
        )

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/pin",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no reply" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PinCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/pin",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_reply))
      end

      it "returns early if reply does not exist" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PinCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply_to = create_message(
          message_id: 50,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
        )

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/pin",
          reply_to_message: reply_to,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PinCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
        )

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/users",
          reply_to_message: reply_to,
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active) 
      end

      it "pins replied to message" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PinCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
        )

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/pin",
          reply_to_message: reply_to,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(3))

        messages.each do |msg|
          unless reply_to = msg.reply_to
            fail("Queued pin message should have a reply here")
          end

          if msg.receiver == 60200
            reply_to.message_id.should(eq(8))
          end
          if msg.receiver == 20000
            reply_to.message_id.should(eq(9))
          end
          if msg.receiver == 80300
            reply_to.message_id.should(eq(10))
          end
        end
      end
    end
  end
end