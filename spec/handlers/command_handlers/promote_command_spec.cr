require "../../spec_helper.cr"

module PrivateParlorXT
  describe PromoteCommand do
    ranks = {
      1000 => Rank.new(
        "Host",
        Set{
          CommandPermissions::Promote,
        },
        Set(MessagePermissions).new,
      ),
      100 => Rank.new(
        "Admin",
        Set{
          CommandPermissions::PromoteLower,
        },
        Set(MessagePermissions).new,
      ),
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::PromoteSame,
        },
        Set(MessagePermissions).new,
      ),
      0 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
      -10 => Rank.new(
        "Blacklisted",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(60200, false, "voorbeeld")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote 40000 admin",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no arguments and no reply" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote 40000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "for PromoteSame permission, promotes user to the same rank as invoker's" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote 40000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        updated_user.rank.should(eq(user.rank))

        expected = Format.substitute_reply(services.replies.promoted, {
          "rank" => "Mod",
        })

        responses = [services.replies.success, expected]

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end
      end

      it "for PromoteLower permission, promotes user to a rank lower than invoker's" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)
        services.database.update_user(user)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote 60200",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should_not(eq(user.rank))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Admin\", \"Mod\", \"User\", \"Blacklisted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        reply_promote_message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote mod",
          from: tourmaline_user,
          reply_to_message: reply_to
        )

        handler.do(reply_promote_message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should(eq(10))

        expected = Format.substitute_reply(services.replies.promoted, {
          "rank" => "Mod",
        })

        responses = [services.replies.success, expected]

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end
      end

      it "for Promote permisson, promotes user to a rank lower than invoker's or to the same rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "beispiel")

        message = create_message(
          message_id: 9,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote 60200 100",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should(eq(100))

        expected = Format.substitute_reply(services.replies.promoted, {
          "rank" => "Admin",
        })

        responses = [services.replies.success, expected]

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end

        reply_to = create_message(
          message_id: 9,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        reply_promote_message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/promote",
          from: tourmaline_user,
          reply_to_message: reply_to
        )

        handler.do(reply_promote_message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.rank.should(eq(1000))

        expected = Format.substitute_reply(services.replies.promoted, {
          "rank" => "Host",
        })

        responses = [services.replies.success, expected]

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end
      end
    end

    describe "#promote_from_reply" do
      it "returns early if message has no arguments and invoker has PromoteLower permission" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.promote_from_reply(nil, :PromoteLower, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns 'no rank found' response when rank in arguments does not exist" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.promote_from_reply("10000", :PromoteLower, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Admin\", \"Mod\", \"User\", \"Blacklisted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.promote_from_reply("mod", :PromoteLower, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns early if reply user cannot be promoted" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.promote_from_reply("host", :PromoteLower, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))

        handler.promote_from_reply("-10", :PromoteLower, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        last_active = user.last_active

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply_to = create_message(
          message_id: 10,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.promote_from_reply("mod", :PromoteLower, user, 11, reply_to, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active.should(be < updated_user.last_active)
      end

      it "promotes reply user to invoker's current rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        generate_users(services.database)
        generate_history(services.history)

        handler = PromoteCommand.new(MockConfig.new)
    
        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_reply(nil, :PromoteSame, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(1000))
      end

      it "promotes reply user to given rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        generate_users(services.database)
        generate_history(services.history)

        handler = PromoteCommand.new(MockConfig.new)

        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_reply("mod", :Promote, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(10))
      end
    end

    describe "#promote_from_args" do
      it "returns early if message has no arguments" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.promote_from_args(nil, :PromoteLower, user, 11, services)

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns 'no rank found' response when rank in arguments does not exist" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.promote_from_args("/promote 60200 10000", :PromoteLower, user, 11, services)

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(0))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Admin\", \"Mod\", \"User\", \"Blacklisted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns early with 'no user found' response if user to promote does not exist" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.promote_from_args("/promote 9000 mod", :PromoteLower, user, 11, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "returns early if reply user cannot be promoted" do 
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.promote_from_args("/promote 60200 host", :PromoteLower, user, 11, services)

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))

        handler.promote_from_args("/promote 60200 -10", :PromoteLower, user, 11, services)

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PromoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        last_active = user.last_active

        handler.promote_from_args("/promote 60200", :Promote, user, 11, services)

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(100))

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active.should(be < updated_user.last_active)
      end

      it "promotes given user to invoker's current rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        generate_users(services.database)

        handler = PromoteCommand.new(MockConfig.new)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          "/promote voorb",
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(1000))
      end

      it "promotes given user to given rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        generate_users(services.database)

        handler = PromoteCommand.new(MockConfig.new)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          "/promote voorb mod",
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(10))
      end

      it "does not promote banned users (unbans)" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        generate_users(services.database)

        handler = PromoteCommand.new(MockConfig.new)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          "/promote 70000 user",
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        promoted_user.rank.should(eq(-10))
      end
    end
  end
end
