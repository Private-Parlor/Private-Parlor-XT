require "../../spec_helper.cr"

module PrivateParlorXT
  describe PrivacyPolicyCommand do
    describe "#do" do
      it "updates user activity" do
        services = create_services()

        handler = PrivacyPolicyCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/privacy",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "sends Privacy Policy to any user" do
        services = create_services(config: HandlerConfig.new(
          MockConfig.new(
            blacklist_contact: "www.example.com"
          )
        ))

        handler = PrivacyPolicyCommand.new(MockConfig.new)

        generate_users(services.database)

        expected = Format.substitute_reply(services.replies.privacy_policy, {
          "contact" => Format.contact(services.config.blacklist_contact, services.replies),
        })

        # Privacy Policy sent to currently joined user

        currently_joined_user = Tourmaline::User.new(60200, false, "voorbeeld")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(currently_joined_user.id, "private"),
          text: "/privacy",
          from: currently_joined_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        # Privacy Policy sent to cooldowned user

        cooldowned_user = Tourmaline::User.new(50000, false, "cooldown")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(cooldowned_user.id, "private"),
          text: "/privacy",
          from: cooldowned_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        # Privacy Policy sent to blacklisted user

        blacklisted_user = Tourmaline::User.new(70000, false, "BLACKLISTED")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(blacklisted_user.id, "private"),
          text: "/privacy",
          from: blacklisted_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        # Privacy Policy sent to left user

        left_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(left_user.id, "private"),
          text: "/privacy",
          from: left_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        # Privacy Policy sent to user not in chat

        not_in_chat_user = Tourmaline::User.new(12345, false, "newbie")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(not_in_chat_user.id, "private"),
          text: "/privacy",
          from: not_in_chat_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end
  end
end
