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

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end
    end

    describe "#blacklist_from_reply" do
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

        handler.do(message, services)

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

    describe "#blacklist_from_args" do
      it "blacklists user from args" do
        generate_users(services.database)
        generate_history(services.history)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/blacklist 60200 detailed reason",
        )

        handler.do(message, services)

        blacklisted_user = services.database.get_user(60200)

        unless blacklisted_user
          fail("User 60200 should exist in the database")
        end

        blacklisted_user.rank.should(eq(-10))
        blacklisted_user.left.should_not(be_nil)
        blacklisted_user.blacklist_reason.should(eq("detailed reason"))
      end
    end

    describe "#blacklist_user" do
      it "returns early if reply user rank is greater than invoker rank" do
        generate_users(services.database)

        unless high_ranked_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        high_ranked_user.set_rank(10000)

        services.database.update_user(high_ranked_user)

        unless low_ranked_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        result = handler.blacklist_user(high_ranked_user, low_ranked_user, 1, nil, services)

        result.should(be_falsey)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "blacklists the given user" do
        generate_users(services.database)

        unless high_ranked_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        high_ranked_user.set_rank(10000)

        services.database.update_user(high_ranked_user)

        unless low_ranked_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        result = handler.blacklist_user(low_ranked_user, high_ranked_user, 1, "detailed reason", services)

        result.should(be_true)

        unless updated_user = services.database.get_user(40000)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should(eq(-10))
        updated_user.left.should_not(be_nil)
        updated_user.blacklist_reason.should(eq("detailed reason"))
      end
    end

    describe "#send_messages" do
      it "sends blacklist messages" do
        generate_users(services.database)

        unless banned_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        unless invoker = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        handler.send_messages(nil, banned_user, invoker, ReplyParameters.new(100), 101, services)

        messages = services.relay.as(MockRelay).empty_queue

        # TODO: Check for channel log messages
        messages.size.should(eq(2))

        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
        })

        log = Format.substitute_message(services.logs.blacklisted, {
          "id"      => banned_user.id.to_s,
          "name"    => banned_user.get_formatted_name,
          "invoker" => invoker.get_formatted_name,
        })

        hash = {response => true, log => true, services.replies.success => true}

        messages.each do |message|
          hash[message.data]?.should(be_true)
        end
      end

      it "sends blacklist messages with reason" do
        generate_users(services.database)

        unless banned_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        unless invoker = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        reason = "detailed reason"

        handler.send_messages(reason, banned_user, invoker, ReplyParameters.new(100), 101, services)

        messages = services.relay.as(MockRelay).empty_queue

        # TODO: Check for channel log messages
        messages.size.should(eq(2))

        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
          "reason"  => Format.format_reason_reply(reason, services.replies),
        })

        log = Format.substitute_message(services.logs.blacklisted, {
          "id"      => banned_user.id.to_s,
          "name"    => banned_user.get_formatted_name,
          "invoker" => invoker.get_formatted_name,
          "reason"  => Format.format_reason_log(reason, services.logs),
        })

        hash = {response => true, log => true, services.replies.success => true}

        messages.each do |message|
          hash[message.data]?.should(be_true)
        end
      end
    end
  end
end
