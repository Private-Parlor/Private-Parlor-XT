require "../../spec_helper.cr"

module PrivateParlorXT
  describe StopCommand do
    describe "#do" do
      it "returns early if message has no sender" do
        services = create_services()

        handler = StopCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/stop",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.left.should(be_nil)
      end

      it "returns early if message text does not start with a command" do
        services = create_services()

        handler = StopCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "stop",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.left.should(be_nil)
      end

      it "returns 'not in chat' response if user does not exist in the database" do
        services = create_services()

        handler = StopCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/stop",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "rejects users that have already left the chat" do
        services = create_services()

        handler = StopCommand.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(40000)

        unless user
          fail("User 40000 should exist in the database")
        end

        previous_left_time = user.left

        tourmaline_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.do(message, services)

        left_user = services.database.get_user(40000)

        unless left_user
          fail("User 40000 should exist in the database")
        end

        left_user.left.should(eq(previous_left_time))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "updates user as having left the chat" do
        services = create_services()

        handler = StopCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.realname.should(eq("beispiel"))

        tourmaline_user = Tourmaline::User.new(80300, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.do(message, services)

        left_user = services.database.get_user(80300)

        unless left_user
          fail("User 80300 should exist in the database")
        end

        left_user.left.should_not(be_nil)
        left_user.realname.should(eq("esimerkki"))
        left_user.last_active.should(be > user.last_active)
      end
    end
  end
end
