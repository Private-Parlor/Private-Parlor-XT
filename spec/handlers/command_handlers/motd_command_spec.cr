require "../../spec_helper.cr"

module PrivateParlorXT
  describe MotdCommand do
    client = MockClient.new

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

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = MotdCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "queues MOTD message" do
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

      it "returns early if user is not authorized to set MOTD" do
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
    end
  end
end
