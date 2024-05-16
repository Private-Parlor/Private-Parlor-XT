require "../../spec_helper.cr"

module PrivateParlorXT
  @[Hears(pattern: /UPDATEHANDLER/, command: true)]
  class ExampleContainsCommand < HearsHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  @[Hears(pattern: "starts_with_UpdateHandler", command: true)]
  class ExampleStartsWithCommand < HearsHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  @[Hears(pattern: "example_hears_UpdateHandler")]
  class ExampleHearshandler < HearsHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  describe MockUpdateHandler do
    describe "#get_user_from_message" do
      it "returns nil if message has no sender" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: nil,
        )

        handler.get_user_from_message(message, services).should(be_nil)
      end

      it "returns nil if message text is a command" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        command_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/test",
        )

        upvote_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "+1",
        )

        downvote_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "-1",
        )

        example_contains_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "This is a message where \"UPDATEHANDLER\" is in the text",
        )

        example_starts_with_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "starts_with_UpdateHandler This is a command",
        )

        handler.get_user_from_message(command_message, services).should(be_nil)
        handler.get_user_from_message(upvote_message, services).should(be_nil)
        handler.get_user_from_message(downvote_message, services).should(be_nil)
        handler.get_user_from_message(example_contains_message, services).should(be_nil)
        handler.get_user_from_message(example_starts_with_message, services).should(be_nil)
      end

      it "returns user" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        reply_tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(reply_tourmaline_user.id, "private"),
          from: reply_tourmaline_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
          from: tourmaline_user
        )

        unless returned_user = handler.get_user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "returns user even if non-command HearsHandler matches text" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "example_hears_UpdateHandler This is not a command, but it matches a hears handler",
          from: tourmaline_user
        )

        unless returned_user = handler.get_user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username")

        new_names_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user
        )

        unless returned_user = handler.get_user_from_message(new_names_message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns nil if user does not exist and queues 'not_in_chat' reply" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        
        tourmaline_user = Tourmaline::User.new(12345678, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user
        )

        handler.get_user_from_message(message, services).should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "returns nil if user cannot chat at this time" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(40000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user
        )

        handler.get_user_from_message(message, services).should(be_nil)
      end
    end

    describe "#authorized?" do
      it "returns true if user can send the given update type" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        authorized_user = MockUser.new(80300, rank: 0)

        handler.authorized?(authorized_user, message, :Text, services).should(be_true)
      end

      it "returns false and queues 'media_disabled' reply if user can't send the given update type" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(70000, false, "BLACKLISTED")
        
        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        unauthorized_user = MockUser.new(70000, rank: -10)

        handler.authorized?(unauthorized_user, message, :Text, services).should(be_false)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        expected = Format.substitute_reply(services.replies.media_disabled, {"type" => :Text.to_s})

        messages[0].data.should(eq(expected))
      end
    end

    describe "#meets_requirements?" do
      it "returns true if message is not a forward or an album" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        handler.meets_requirements?(message).should(be_true)
      end

      it "returns false if message is a forward" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.meets_requirements?(message).should(be_false)
      end

      it "returns false if message is an album" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          media_group_id: "10000"
        )

        handler.meets_requirements?(message).should(be_false)
      end
    end

    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: -10)

        handler.deny_user(user, services)

        messages = services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "queues cooldowned response when user is cooldowned" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 0)

        user.cooldown(30.minutes)

        handler.deny_user(user, services)

        messages = services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(services.replies.on_cooldown, {
          "time" => Format.format_time(user.cooldown_until, services.locale.time_format),
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "queues media limit response when user can't send media" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              media_limit_period: 5,
            )
          )
        )

        handler = MockUpdateHandler.new(MockConfig.new)

        user = MockUser.new(9000, joined: Time.utc, rank: 0)

        handler.deny_user(user, services)

        messages = services.relay.as(MockRelay).empty_queue

        blacklisted_message = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        cooldown_message = Format.substitute_reply(services.replies.on_cooldown, {
          "time" => Format.format_time(user.cooldown_until, services.locale.time_format),
        })

        messages.size.should(eq(1))
        messages[0].data.should_not(eq(blacklisted_message))
        messages[0].data.should_not(eq(cooldown_message))
        messages[0].data.should_not(eq(services.replies.not_in_chat))
      end

      it "queues not in chat message when user still can't chat" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              media_limit_period: 0,
            )
          )
        )

        handler = MockUpdateHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 0)

        handler.deny_user(user, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_chat))
      end
    end

    describe "#get_reply_receivers" do
      it "returns hash of reply message receivers if reply exists" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        reply_tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(reply_tourmaline_user.id, "private"),
          from: reply_tourmaline_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[20000].message_id.should(eq(5))
        hash[60200].message_id.should(eq(7))
      end

      it "returns an empty hash if message did not contain a reply" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned an empty hash of reply message receivers")
        end

        hash.should(be_empty)
      end

      it "returns hash of reply message receivers if self-quoted message has stripped entities" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "Example text with entities",
          entities: [Tourmaline::MessageEntity.new(type: "bold", offset: 0, length: 7)]
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
          quote: Tourmaline::TextQuote.new(
            text: "Example text with entities",
            position: 0,
            entities: [Tourmaline::MessageEntity.new(type: "bold", offset: 0, length: 7)]
          )
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[60200].message_id.should(eq(2))
        hash[60200].quote.should(be_nil)
        hash[20000].message_id.should(eq(3))
        hash[20000].quote.should(be_nil)
      end

      it "returns hash of reply message receivers if self-quoted message is edited" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "Example text with entities",
        )

        reply.edit_date = Time.utc

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
          quote: Tourmaline::TextQuote.new(
            text: "Example text with entities",
            position: 0,
          )
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[60200].message_id.should(eq(2))
        hash[60200].quote.should(be_nil)
        hash[20000].message_id.should(eq(3))
        hash[20000].quote.should(be_nil)
      end

      it "returns hash of reply message receivers with quotes" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        reply_tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(reply_tourmaline_user.id, "private"),
          from: reply_tourmaline_user,
          text: "Example text with entities",
        )

        reply.edit_date = Time.utc

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
          quote: Tourmaline::TextQuote.new(
            text: "Example text with entities",
            position: 0,
            entities: [Tourmaline::MessageEntity.new(type: "bold", offset: 0, length: 7)]
          )
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[20000].message_id.should(eq(5))
        hash[20000].quote.should(eq("Example text with entities"))
        hash[20000].quote_entities.size.should(eq(1))
        hash[20000].quote_entities[0].type.should(eq("bold"))
        hash[20000].quote_position.should(eq(0))

        hash[60200].message_id.should(eq(7))
        hash[60200].quote.should(eq("Example text with entities"))
        hash[60200].quote_entities.size.should(eq(1))
        hash[60200].quote_entities[0].type.should(eq("bold"))
        hash[60200].quote_position.should(eq(0))
      end

      it "returns nil and queues 'not_in_cache' reply if message has a reply but it is not cached" do 
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        reply_tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(reply_tourmaline_user.id, "private"),
          from: reply_tourmaline_user
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          reply_to_message: reply,
        )

        user = MockUser.new(80300, rank: 10)

        handler.get_reply_receivers(message, user, services).should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end
    end

    describe "#get_message_receivers" do
      it "returns array of user IDs without given user ID" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        user = MockUser.new(80300, rank: 10)

        handler.get_message_receivers(user, services).should_not(contain(user.id))
      end

      it "returns array of user IDs including given user if debug is enabled" do
        services = create_services()
        handler = MockUpdateHandler.new(MockConfig.new)

        generate_users(services.database)

        user = MockUser.new(80300, rank: 10)

        user.toggle_debug

        handler.get_message_receivers(user, services).should(contain(user.id))
      end
    end
    
    describe "#record_message_statistics" do
      it "increments message count and total message counts based on given type" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        db = SQLiteDatabase.new(connection)
        stats = SQLiteStatistics.new(connection)

        services = create_services(statistics: stats)
        handler = MockUpdateHandler.new(MockConfig.new)

        handler.record_message_statistics(:Audio, services)

        stats.get_total_messages[Statistics::MessageCounts::Audio].should(eq(1))
        stats.get_total_messages[Statistics::MessageCounts::TotalMessages].should(eq(1))
      end
    end
  end
end
