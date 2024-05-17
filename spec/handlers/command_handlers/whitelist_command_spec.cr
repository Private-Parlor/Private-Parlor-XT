require "../../spec_helper.cr"

module PrivateParlorXT
  describe WhitelistCommand do
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

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false,
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/whitelist 9000",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if registration is open" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: true,
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/whitelist 9000",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "returns early if given no argument, or argument is not a number" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false,
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "beispiel")

        no_arg_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/whitelist",
          from: tourmaline_user
        )

        handler.do(no_arg_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.missing_args))

        invalid_arg_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/whitelist example",
          from: tourmaline_user
        )

        handler.do(invalid_arg_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns early if user exists with the given ID" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false,
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/whitelist 80300",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.already_whitelisted))
      end

      it "updates user actitivy" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false,
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/whitelist 9000",
          from: tourmaline_user
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "whitelists user with given user ID" do
        services = create_services(
          ranks: ranks,
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false,
              default_rank: 10
            ),
          ),
        )

        handler = WhitelistCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/whitelist 9000",
        )

        handler.do(message, services)

        whitelisted_user = services.database.get_user(9000)

        unless whitelisted_user
          fail("User 9000 should exist in the database")
        end

        whitelisted_user.rank.should(eq(10))
        whitelisted_user.realname.should(eq("WHITELISTED"))

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(2))

        messages.each do |msg|
          if msg.receiver == 9000
            msg.data.should(eq(services.replies.added_to_chat))
          end

          if msg.receiver == 20000
            msg.data.should(eq(services.replies.success))
          end
        end
      end
    end
  end
end
