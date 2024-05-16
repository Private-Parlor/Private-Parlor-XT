require "../../spec_helper.cr"

module PrivateParlorXT
  describe UnblacklistCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Unblacklist,
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
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unblacklist user",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no args" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unblacklist",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns early if no user could be found with args" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unblacklist 9000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "returns early if user is not blacklisted" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unblacklist voorb",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/unblacklist 70000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active) 
      end

      it "unblacklists the given user by ID" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless blacklisted_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        services.database.update_user(blacklisted_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/unblacklist 70000",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        updated_user.rank.should_not(eq(-10))
        updated_user.left.should(be_nil)
      end

      it "does not unblacklist the given user by OID" do
        services = create_services(ranks: ranks)

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless blacklisted_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        obfuscated_id = blacklisted_user.get_obfuscated_id

        services.database.update_user(blacklisted_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/unblacklist #{obfuscated_id}",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        updated_user.rank.should(eq(-10))
        updated_user.left.should_not(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "unblacklists the given user by username" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 100
            ),
          ),
        )

        handler = UnblacklistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless blacklisted_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        blacklisted_user.update_names("blacklisted_user", "BLACKLISTED")

        services.database.update_user(blacklisted_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/unblacklist blacklisted_user",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        updated_user.rank.should(eq(100))
        updated_user.left.should(be_nil)
      end
    end
  end
end