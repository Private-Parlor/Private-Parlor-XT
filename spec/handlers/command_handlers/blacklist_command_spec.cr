require "../../spec_helper.cr"

module PrivateParlorXT
  describe BlacklistCommand do
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

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/blacklist detailed reason",
          reply_to_message: reply,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no arguments and no reply" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/blacklist",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/blacklist",
          from: tourmaline_user,
          reply_to_message: reply,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "blacklists a user" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)
        
        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/blacklist",
          from: tourmaline_user,
          reply_to_message: reply,
        )

        handler.do(message, services)

        unless blacklisted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        blacklisted_user.rank.should(eq(-10))
        blacklisted_user.left.should_not(be_nil)
        blacklisted_user.blacklist_reason.should(be_nil)

        message = Tourmaline::Message.new(
          message_id: 12,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/blacklist 80300 detailed reason",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless blacklisted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        blacklisted_user.rank.should(eq(-10))
        blacklisted_user.left.should_not(be_nil)
        blacklisted_user.blacklist_reason.should(eq("detailed reason"))
      end
    end

    describe "#blacklist_from_reply" do
      it "returns early with 'not in cache' response if reply message does not exist in message history" do 
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/blacklist detailed reason",
          reply_to_message: reply,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "blacklists reply user" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/blacklist detailed reason",
          reply_to_message: reply,
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
      it "returns early with 'no user found' response if user to blacklist does not exist" do 
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/blacklist 9000 detailed reason",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "blacklists user from args" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/blacklist 60200",
        )

        handler.do(message, services)

        blacklisted_user = services.database.get_user(60200)

        unless blacklisted_user
          fail("User 60200 should exist in the database")
        end

        blacklisted_user.rank.should(eq(-10))
        blacklisted_user.left.should_not(be_nil)
        blacklisted_user.blacklist_reason.should(be_nil)
      end
    end

    describe "#blacklist_user" do
      it "returns early if reply user rank is greater than invoker rank" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

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

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless high_ranked_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        high_ranked_user.set_rank(10000)

        services.database.update_user(high_ranked_user)

        last_active = high_ranked_user.last_active

        unless low_ranked_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        handler.blacklist_user(low_ranked_user, high_ranked_user, 1, "detailed reason", services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        last_active.should(be < updated_user.last_active)
      end

      it "blacklists the given user" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless high_ranked_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        high_ranked_user.set_rank(10000)

        services.database.update_user(high_ranked_user)

        unless low_ranked_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        # Add messages adressed to and sent by the user to blacklist
        services.relay.send_to_user(nil, low_ranked_user.id, "message")
        services.relay.send_text(
          RelayParameters.new(
            original_message: 1_i64,
            sender: low_ranked_user.id,
            receivers: [9000_i64, 10000_i64, 11000_i64],
          )
        )

        result = handler.blacklist_user(low_ranked_user, high_ranked_user, 1, "detailed reason", services)

        result.should(be_true)

        unless updated_user = services.database.get_user(40000)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should(eq(-10))
        updated_user.left.should_not(be_nil)
        updated_user.blacklist_reason.should(eq("detailed reason"))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end
    end

    describe "#send_messages" do
      it "sends blacklist messages" do
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless banned_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        unless invoker = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        handler.send_messages(nil, banned_user, invoker, ReplyParameters.new(100), 101, services)

        messages = services.relay.as(MockRelay).empty_queue
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
        services = create_services(ranks: ranks)

        handler = BlacklistCommand.new(MockConfig.new)

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
