require "../../spec_helper.cr"

module PrivateParlorXT
  describe VersionCommand do
    describe "#do" do
      it "updates user activity" do
        services = create_services()

        handler = VersionCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/version",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "queues message with link to source code" do
        services = create_services()

        handler = VersionCommand.new(MockConfig.new)

        generate_users(services.database)

        unless services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/version",
          from: tourmaline_user,
        )

        handler.do(message, services)

        expected = handler.version

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end

    describe "#version" do
      it "returns string containing source code link and information" do
        handler = VersionCommand.new(MockConfig.new)

        expected = "Private Parlor XT vspec \\~ [\\[Source\\]](https://github.com/Private-Parlor/Private-Parlor-XT)"

        handler.version.should(eq(expected))
      end
    end
  end
end
