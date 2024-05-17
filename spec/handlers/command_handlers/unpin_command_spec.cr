require "../../spec_helper.cr"

module PrivateParlorXT
  describe UnpinCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Unpin,
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
        services = create_services()

        handler = UnpinCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unpin",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if unpinning with reply and reply does not exist" do
        services = create_services(ranks: ranks)

        handler = UnpinCommand.new(MockConfig.new)

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
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unpin",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = UnpinCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/users",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "unpins replied to message" do
        services = create_services(ranks: ranks)

        handler = UnpinCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unpin",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages[0].data.should(eq(services.replies.success))

        messages[1..-1].each do |msg|
          unless reply_to_message = msg.reply
            fail("Queued unpin message should have a reply here")
          end

          if msg.receiver == 60200
            reply_to_message.message_id.should(eq(8))
          end
          if msg.receiver == 20000
            reply_to_message.message_id.should(eq(9))
          end
          if msg.receiver == 80300
            reply_to_message.message_id.should(eq(10))
          end
        end
      end

      it "unpins most recently pinned message" do
        services = create_services(ranks: ranks)

        handler = UnpinCommand.new(MockConfig.new)

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
          text: "/unpin",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(5))

        messages[0].data.should(eq(services.replies.success))

        messages[1..-1].each do |msg|
          msg.reply.should(be_nil)
        end
      end
    end
  end
end
