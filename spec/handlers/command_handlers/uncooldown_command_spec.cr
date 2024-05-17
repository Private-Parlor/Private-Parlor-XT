require "../../spec_helper.cr"

module PrivateParlorXT
  describe UncooldownCommand do
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

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/uncooldown user",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no args" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/uncooldown",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns early if no user could be found with args" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/uncooldown 9000",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_user_found))
      end

      it "returns early if user is not on cooldown" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/uncooldown voorb",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cooldown))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless cooldowned_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = cooldowned_user.warnings

        cooldowned_user.cooldown(10.minutes)

        services.database.update_user(cooldowned_user)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/uncooldown voorb",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active) 
      end

      it "uncooldowns the given user by ID" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless cooldowned_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = cooldowned_user.warnings

        cooldowned_user.cooldown(10.minutes)

        services.database.update_user(cooldowned_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/uncooldown 60200",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.warnings.should(be < prior_warnings)
        updated_user.cooldown_until.should(be_nil)
      end

      it "uncooldowns the given user by OID" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless cooldowned_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = cooldowned_user.warnings
        obfuscated_id = cooldowned_user.obfuscated_id

        cooldowned_user.cooldown(10.minutes)

        services.database.update_user(cooldowned_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/uncooldown #{obfuscated_id}",
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        updated_user.warnings.should(be < prior_warnings)
        updated_user.cooldown_until.should(be_nil)
      end

      it "uncooldowns the given user by username" do
        services = create_services(ranks: ranks)

        handler = UncooldownCommand.new(MockConfig.new)

        generate_users(services.database)

        unless cooldowned_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        prior_warnings = cooldowned_user.warnings

        cooldowned_user.cooldown(10.minutes)

        services.database.update_user(cooldowned_user)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/uncooldown voorb",
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
