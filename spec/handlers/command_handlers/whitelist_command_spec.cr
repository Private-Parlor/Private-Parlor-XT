require "../../spec_helper.cr"

module PrivateParlorXT
  describe WhitelistCommand do
    client = MockClient.new

    config = HandlerConfig.new(
      MockConfig.new(
        registration_open: false,
      ),
    )

    ranks = {
      1000 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Whitelist,
        },
        Set(MessagePermissions).new,
      ),
      10 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, config: config, relay: MockRelay.new("", client))

    handler = WhitelistCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, config: config, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/whitelist 9000",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if registration is open" do
        open_registration_services = create_services(
          ranks: ranks,
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: true,
            ),
          ),
        )

        generate_users(open_registration_services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/whitelist 9000",
        )

        handler.do(message, open_registration_services)

        messages = open_registration_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(open_registration_services.replies.fail))
      end

      it "whitelists user with given user ID" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/whitelist 9000",
        )

        handler.do(message, services)

        whitelisted_user = services.database.get_user(9000)

        unless whitelisted_user
          fail("User 9000 should exist in the database")
        end

        whitelisted_user.rank.should(eq(0))
        whitelisted_user.realname.should(eq("WHITELISTED"))
      end
    end
  end
end
