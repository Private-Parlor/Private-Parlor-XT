require "../../spec_helper.cr"

module PrivateParlorXT
  describe ToggleKarmaCommand do
    describe "#do" do
      it "updates user activity" do
        services = create_services()

        handler = ToggleKarmaCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/toggle_karma",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "toggles karma notifications" do
        services = create_services()

        handler = ToggleKarmaCommand.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(20000)

        unless user
          fail("User 20000 should exist in the database")
        end

        previous_toggle = user.hide_karma

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/toggle_karma",
          from: tourmaline_user,
        )

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.hide_karma.should_not(eq(previous_toggle))

        expected = Format.substitute_reply(services.replies.toggle_karma, {
          "toggle" => services.locale.toggle[0],
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        # Restore hide_karma value

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.hide_karma.should(eq(previous_toggle))

        expected = Format.substitute_reply(services.replies.toggle_karma, {
          "toggle" => services.locale.toggle[1],
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end
  end
end
