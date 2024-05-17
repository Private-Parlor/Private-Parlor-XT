require "../../spec_helper.cr"

module PrivateParlorXT
  describe StartCommand do
    describe "#do" do
      it "returns early if message has no sender" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))

        unless user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        user.left.should_not(be_nil)
      end

      it "returns early if message text does not start with a command" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))

        unless user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        user.left.should_not(be_nil)
      end

      it "returns 'blacklisted' response if user is blacklsited" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(70000, false, "BLACKLISTED")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        user.left.should_not(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(Format.substitute_message(services.replies.blacklisted)))
      end

      it "rejoins user and returns 'rejoined' response" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(40000)
          fail("User 40000 should exist in the database")
        end

        user.left.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.rejoined))
      end

      it "returns 'already in chat' reponse if user is already joined" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.left.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.already_in_chat))
      end

      it "returns 'registration closed' when bot is not open for registration" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        user = services.database.get_user(9000)

        user.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(Format.substitute_message(services.replies.registration_closed)))
      end

      it "adds new user with highest rank if there are no users in the database" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(9000)
          fail("User 9000 should exist in the database")
        end

        user.rank.should(eq(services.access.max_rank))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(Format.substitute_message(services.replies.joined)))
      end

      it "adds new user with default rank if there are users in database" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 10
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(9000)
          fail("User 9000 should exist in the database")
        end

        user.rank.should(eq(10))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.joined))
      end

      it "returns pseudonymous response when user joins bot with pseudonymous mode enabled" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(9000)
          fail("User 9000 should exist in the database")
        end

        user.rank.should(eq(services.access.max_rank))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.joined_pseudonym))
      end

      it "returns 'MOTD' response when the MOTD/rules are set" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        services.database.set_motd("Message of the day")

        tourmaline_user = Tourmaline::User.new(9000, false, "user9000")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/start",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless user = services.database.get_user(9000)
          fail("User 9000 should exist in the database")
        end

        user.rank.should(eq(services.access.max_rank))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        responses = [services.replies.joined, "Message of the day"]

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end
      end
    end

    describe "#existing_user" do
      it "rejects blacklisted users" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(70000)

        unless user
          fail("User 70000 should exist in the database")
        end

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        blacklisted_user = services.database.get_user(70000)

        unless blacklisted_user
          fail("User 70000 should exist in the database")
        end

        blacklisted_user.username.should_not(eq("joined"))
        blacklisted_user.realname.should_not(eq("new user"))
      end

      it "rejoins users that have previously left" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(40000)

        unless user
          fail("User 40000 should exist in the database")
        end

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        rejoined_user = services.database.get_user(40000)

        unless rejoined_user
          fail("User 40000 should exist in the database")
        end

        rejoined_user.username.should_not(be_nil)
        rejoined_user.realname.should_not(eq("esimerkki"))
        rejoined_user.username.should(eq("joined"))
        rejoined_user.realname.should(eq("new user"))
        rejoined_user.left.should(be_nil)
      end

      it "updates activity for users that are already joined" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        previous_activity = user.last_active

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        updated_user = services.database.get_user(60200)

        unless updated_user
          fail("User 60200 should exist in the database")
        end

        updated_user.username.should_not(eq("voorb"))
        updated_user.realname.should_not(eq("voorbeeld"))
        updated_user.username.should(eq("joined"))
        updated_user.realname.should(eq("new user"))
        updated_user.last_active.should(be > previous_activity)
      end
    end

    describe "#new_user" do
      it "rejects user if registration is closed" do
        closed_registration_services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              registration_open: false
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        handler.new_user(9000, nil, "new user", 1_i64, closed_registration_services)

        closed_registration_services.database.get_user(9000).should(be_nil)
      end

      it "adds user to database with max rank" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        handler.new_user(9000, nil, "new user", 1_i64, services)

        new_user = services.database.get_user(9000)

        unless new_user
          fail("User 9000 should have been added to the database")
        end

        new_user.rank.should(eq(services.access.max_rank))
      end

      it "adds user to database with default rank" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              default_rank: 10
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        generate_users(services.database)

        handler.new_user(9000, nil, "new user", 1_i64, services)

        new_user = services.database.get_user(9000)

        unless new_user
          fail("User 9000 should have been added to the database")
        end

        new_user.rank.should(eq(10))
      end

      it "returns 'pseudonymous' response when user joins bot with pseudonymous mode enabled" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true
            )
          )
        )

        handler = StartCommand.new(MockConfig.new)

        handler.new_user(9000, nil, "new user", 1_i64, services)

        new_user = services.database.get_user(9000)

        unless new_user
          fail("User 9000 should have been added to the database")
        end

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.joined_pseudonym))
      end

      it "returns 'MOTD' reponse when the MOTD/rules are set" do
        services = create_services()

        handler = StartCommand.new(MockConfig.new)

        services.database.set_motd("Message of the day")

        handler.new_user(9000, nil, "new user", 1_i64, services)

        unless user = services.database.get_user(9000)
          fail("User 9000 should exist in the database")
        end

        user.rank.should(eq(services.access.max_rank))

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        responses = [services.replies.joined, "Message of the day"]

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)
          responses = responses - [msg.data]
        end
      end
    end
  end
end
