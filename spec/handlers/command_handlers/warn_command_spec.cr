require "../../spec_helper.cr"

module PrivateParlorXT
  describe WarnCommand do
    client = MockClient.new

    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Warn,
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

    handler = WarnCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        generate_users(services.database)

        reply_to = create_message(
          10,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "beispiel"),
          text: "/warn detailed reason",
          reply_to_message: reply_to,
        )

        

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "warns the user who sent the reply message" do
        generate_users(services.database)
        generate_history(services.history)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = reply_user.warnings

        reply_to = create_message(
          10,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/warn detailed reason",
          reply_to_message: reply_to,
        )

        

        handler.do(message, services)

        services.history.get_origin_message(10).should_not(be_nil)

        unless updated_reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_reply_user.warnings.should(be > prior_warnings)
      end
    end
  end
end
