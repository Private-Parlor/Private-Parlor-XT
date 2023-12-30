require "../../spec_helper.cr"

module PrivateParlorXT
  describe MockUpdateHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = MockUpdateHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#get_message_and_user" do
      it "returns message and user" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        tuple = handler.get_message_and_user(message, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end
        unless returned_user = tuple[1]
          fail("Did not get a user from method")
        end

        returned_message.should(eq(message))

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        new_names_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username"),
        )

        new_names_context = create_context(client, create_update(11, new_names_message))

        tuple = handler.get_message_and_user(new_names_message, services)

        unless tuple[0]
          fail("Did not get a message from method")
        end
        unless returned_user = tuple[1]
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns message if user does not exist" do
        no_user_message = create_message(
          11,
          Tourmaline::User.new(9000, false, "no_user"),
        )

        no_user_context = create_context(client, create_update(11, no_user_message))

        tuple = handler.get_message_and_user(no_user_message, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(no_user_message))
      end

      it "returns message if user can't send an update message (blacklisted)" do
        blacklisted_user_message = create_message(
          11,
          Tourmaline::User.new(70000, false, "BLACKLISTED"),
        )

        blacklisted_user_context = create_context(client, create_update(11, blacklisted_user_message))

        tuple = handler.get_message_and_user(blacklisted_user_message, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(blacklisted_user_message))
      end

      it "returns message if user can't send an update message (cooldowned)" do
        cooldowned_user_message = create_message(
          11,
          Tourmaline::User.new(50000, false, "cooldown"),
        )

        cooldowned_user_context = create_context(client, create_update(11, cooldowned_user_message))

        tuple = handler.get_message_and_user(cooldowned_user_message, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(cooldowned_user_message))
      end

      it "returns message if user can't send an update message (media limit period)" do
        services.database.add_user(1234_i64, nil, "new_user", 0)

        limited_user_message = create_message(
          11,
          Tourmaline::User.new(1234, false, "new_user"),
        )

        limited_user_context = create_context(client, create_update(11, limited_user_message))

        tuple = handler.get_message_and_user(limited_user_message, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(limited_user_message))
      end

      # TODO: Relook at this test
      # it "returns nil if message does not exist" do
      #   empty_context = create_context(client, create_update(11))

      #   tuple = handler.get_message_and_user(empty_context, services)

      #   tuple.should(eq({nil, nil}))
      # end

      it "returns nil if message text starts with a command" do
        command_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/test",
        )

        upvote_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "+1",
        )

        downvote_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "-1",
        )

        command_context = create_context(client, create_update(11, command_message))
        upvote_context = create_context(client, create_update(11, upvote_message))
        downvote_context = create_context(client, create_update(11, downvote_message))

        command_tuple = handler.get_message_and_user(command_message, services)
        upvote_tuple = handler.get_message_and_user(upvote_message, services)
        downvote_tuple = handler.get_message_and_user(downvote_message, services)

        command_tuple.should(eq({nil, nil}))
        upvote_tuple.should(eq({nil, nil}))
        downvote_tuple.should(eq({nil, nil}))
      end
    end

    describe "#authorized?" do
      it "returns true if user can send update" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        handler.authorized?(beispiel, message, :Text, services).should(be_true)
      end

      it "returns false if user can't send update" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        unauthorized_user = MockUser.new(9000, rank: -10)

        handler.authorized?(unauthorized_user, message, :Text, services).should(be_false)
      end
    end

    describe "#meets_requirements?" do
      it "returns true if message is not a forward or an album" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        handler.meets_requirements?(message).should(be_true)
      end

      it "returns false if message is a forward" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.meets_requirements?(message).should(be_false)
      end

      it "returns false if message is an album" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          media_group_id: "10000"
        )

        handler.meets_requirements?(message).should(be_false)
      end
    end

    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        mock_services = create_services(relay: MockRelay.new("", client))

        user = MockUser.new(9000, rank: -10)

        handler.deny_user(user, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(mock_services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "queues cooldowned response when user is cooldowned" do
        mock_services = create_services(relay: MockRelay.new("", client))

        user = MockUser.new(9000, rank: 0)

        user.cooldown(30.minutes)

        handler.deny_user(user, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(mock_services.replies.on_cooldown, {
          "time" => Format.format_time(user.cooldown_until, mock_services.locale.time_format),
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "queues media limit response when user can't send media" do
        mock_services = create_services(
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              media_limit_period: 5,
            )
          )
        )

        user = MockUser.new(9000, joined: Time.utc, rank: 0)

        handler.deny_user(user, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        blacklisted_message = Format.substitute_reply(mock_services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        cooldown_message = Format.substitute_reply(mock_services.replies.on_cooldown, {
          "time" => Format.format_time(user.cooldown_until, mock_services.locale.time_format),
        })

        messages.size.should(eq(1))
        messages[0].data.should_not(eq(blacklisted_message))
        messages[0].data.should_not(eq(cooldown_message))
        messages[0].data.should_not(eq(mock_services.replies.not_in_chat))
      end

      it "queues not in chat message when user still can't chat" do
        mock_services = create_services(
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              media_limit_period: 0,
            )
          )
        )

        user = MockUser.new(9000, rank: 0)

        handler.deny_user(user, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(mock_services.replies.not_in_chat))
      end
    end

    describe "#get_reply_receivers" do
      it "returns hash of reply message receivers if reply exists" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        user = MockUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[20000].message_id.should(eq(5))
        hash[60200].message_id.should(eq(7))
      end

      it "returns an empty hash if reply does not exist in cache" do
        reply_to = create_message(
          10000,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        user = MockUser.new(80300, rank: 10)

        handler.get_reply_receivers(message, user, services).should(be_empty)
      end
    end

    describe "#get_message_receivers" do
      it "returns array of user IDs without given user ID" do
        user = MockUser.new(80300, rank: 10)

        handler.get_message_receivers(user, services).should_not(contain(user.id))
      end

      it "returns array of user IDs including given user if debug is enabled" do
        user = MockUser.new(80300, rank: 10)

        user.toggle_debug

        handler.get_message_receivers(user, services).should(contain(user.id))
      end
    end
  end
end
