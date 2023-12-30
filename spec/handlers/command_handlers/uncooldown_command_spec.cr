require "../../spec_helper.cr"

module PrivateParlorXT
  describe UncooldownCommand do
    client = MockClient.new

    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Uncooldown,
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

    handler = UncooldownCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "beispiel"),
          text: "/uncooldown user",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "uncooldowns the given user by ID" do
        generate_users(services.database)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = reply_user.warnings

        reply_user.cooldown(10.minutes)

        services.database.update_user(reply_user)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/uncoodown 60200",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.warnings.should(be < prior_warnings)
        updated_user.cooldown_until.should(be_nil)
      end

      it "uncooldowns the given user by OID" do
        generate_users(services.database)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = reply_user.warnings
        obfuscated_id = reply_user.get_obfuscated_id

        reply_user.cooldown(10.minutes)

        services.database.update_user(reply_user)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/uncoodown #{obfuscated_id}",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.warnings.should(be < prior_warnings)
        updated_user.cooldown_until.should(be_nil)
      end

      it "uncooldowns the given user by username" do
        generate_users(services.database)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = reply_user.warnings

        reply_user.cooldown(10.minutes)

        services.database.update_user(reply_user)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/uncoodown voorb",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.warnings.should(be < prior_warnings)
        updated_user.cooldown_until.should(be_nil)
      end
    end
  end
end
