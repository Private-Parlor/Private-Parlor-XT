require "../../spec_helper.cr"

module PrivateParlorXT
  describe DemoteCommand do
    ranks = {
      1000 => Rank.new(
        "Host",
        Set{
          CommandPermissions::Demote,
        },
        Set(MessagePermissions).new,
      ),
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Demote,
        },
        Set(MessagePermissions).new,
      ),
      0 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
      -5 => Rank.new(
        "Restricted",
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
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(60200, false, "voorbeeld")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/demote 40000 admin",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no arguments and no reply" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/demote",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "updates user activity" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: -5
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/demote 40000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "demotes a user" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: -5
            )
          ),
        )

        generate_users(services.database)

        handler = DemoteCommand.new(MockConfig.new)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/demote -50",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should_not(eq(-50))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Mod\", \"User\", \"Restricted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        message = Tourmaline::Message.new(
          message_id: 12,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/demote 40000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless demoted_user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        demoted_user.rank.should(eq(-5))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.success))
      end
    end

    describe "#demote_from_reply" do
      it "returns 'no rank found' response when rank in arguments does not exist" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.demote_from_reply("10000", user, 11, reply, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Mod\", \"User\", \"Restricted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do 
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.demote_from_reply("mod", user, 11, reply, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns early if reply user cannot be demoted" do 
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.demote_from_reply("host", user, 11, reply, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))

        handler.demote_from_reply("-10", user, 11, reply, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: -5
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active = user.last_active

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        handler.demote_from_reply("restricted", user, 11, reply, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active.should(be < updated_user.last_active)
      end

      it "demotes reply user to default rank" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0 
            )
          ),
        )

        generate_users(services.database)
        generate_history(services.history)

        handler = DemoteCommand.new(MockConfig.new)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 3,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_reply(nil, user, 11, reply, services)

        unless reply_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user.rank.should(eq(0))
      end

      it "demotes reply user to the given rank" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        generate_users(services.database)

        handler = DemoteCommand.new(MockConfig.new)

        # Set user rank to admin for this test
        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        services.database.update_user(demoted_user)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 3,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_reply("mod", user, 11, reply, services)

        unless reply_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user.rank.should(eq(10))
      end
    end

    describe "#demote_from_args" do
      it "returns early if message has no arguments" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.demote_from_args(nil, user, 11, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns 'no rank found' response when rank in arguments does not exist" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.demote_from_args("/demote 60200 10000", user, 11, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should(eq(0))

        expected = Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => "[\"Mod\", \"User\", \"Restricted\"]",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns early with 'no user found' response if user to demote does not exist" do 
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.demote_from_args("/demote 9000 mod", user, 11, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "returns early if reply user cannot be demoted" do 
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(100)

        handler.demote_from_args("/demote 60200 host", user, 11, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))

        handler.demote_from_args("/demote 60200 -10", user, 11, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should(eq(0))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: -5
            )
          ),
        )

        handler = DemoteCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active = user.last_active

        handler.demote_from_args("/demote 60200", user, 11, services)

        unless demoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        demoted_user.rank.should(eq(-5))

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        last_active.should(be < updated_user.last_active)
      end

      it "demotes given user to default rank" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        generate_users(services.database)

        handler = DemoteCommand.new(MockConfig.new)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_args("/demote 80300", user, 11, services)

        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        demoted_user.rank.should(eq(0))
      end

      it "demotes given user to the given rank" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 0
            )
          ),
        )

        generate_users(services.database)

        handler = DemoteCommand.new(MockConfig.new)

        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        demoted_user.set_rank(100)
        services.database.update_user(demoted_user)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_args("/demote 80300 mod", user, 11, services)

        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        demoted_user.rank.should(eq(10))
      end
    end
  end
end
