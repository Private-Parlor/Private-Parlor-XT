require "../../spec_helper.cr"

module PrivateParlorXT
  describe BlacklistCommand do
    client = MockClient.new

    ranks = {
      1000 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Blacklist,
        },
        Set(MessagePermissions).new,
      ),
      10 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = BlacklistCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        generate_users(services.database)
        generate_history(services.history)

        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/blacklist detailed reason",
          reply_to_message: reply_to,
        )
          
        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if reply user rank is greater than invoker rank" do
        generate_users(services.database)
        generate_history(services.history)

        unless high_ranked_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        high_ranked_user.set_rank(10000)

        services.database.update_user(high_ranked_user)

        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/blacklist detailed reason",
          reply_to_message: reply_to,
        )
          
        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "blacklists reply user" do
        generate_users(services.database)
        generate_history(services.history)

        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/blacklist detailed reason",
          reply_to_message: reply_to,
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        services.history.get_origin_message(9).should(be_nil)

        blacklisted_user = services.database.get_user(60200)

        unless blacklisted_user
          fail("User 60200 should exist in the database")
        end

        blacklisted_user.rank.should(eq(-10))
        blacklisted_user.left.should_not(be_nil)
        blacklisted_user.blacklist_reason.should(eq("detailed reason"))
      end
    end
  end
end