require "../../spec_helper.cr"

module PrivateParlorXT
  describe MotdCommand do
    ranks = {
      1000 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::MotdSet,
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
      it "returns early if user is not authorized to set MOTD" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = MotdCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/motd *new* motd",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))

        services.database.get_motd.should(be_nil)
      end

      it "updates user activity" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = MotdCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/motd",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "returns early if MOTD is not set" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = MotdCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/motd",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "queues MOTD message" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = MotdCommand.new(MockConfig.new)

        services.database.set_motd("example motd")

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/motd",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq("example motd"))
      end

      it "sets MOTD message" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = MotdCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/motd *new* motd example",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.success))

        services.database.get_motd.should(eq("*new* motd example"))
      end
    end
  end
end
