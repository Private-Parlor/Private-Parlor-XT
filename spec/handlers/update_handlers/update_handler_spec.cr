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

        ctx = create_context(client, create_update(11, message))

        tuple = handler.get_message_and_user(ctx, services)

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

        tuple = handler.get_message_and_user(new_names_context, services)

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

        tuple = handler.get_message_and_user(no_user_context, services)

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

        tuple = handler.get_message_and_user(blacklisted_user_context, services)

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

        tuple = handler.get_message_and_user(cooldowned_user_context, services)

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

        tuple = handler.get_message_and_user(limited_user_context, services)

        unless returned_message = tuple[0]
          fail("Did not get a message from method")
        end

        tuple[1].should(be_nil)
        returned_message.should(eq(limited_user_message))
      end

      it "returns nil if message does not exist" do
        empty_context = create_context(client, create_update(11))

        tuple = handler.get_message_and_user(empty_context, services)

        tuple.should(eq({nil, nil}))
      end

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

        command_tuple = handler.get_message_and_user(command_context, services)
        upvote_tuple = handler.get_message_and_user(upvote_context, services)
        downvote_tuple = handler.get_message_and_user(downvote_context, services)

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

        unauthorized_user = SQLiteUser.new(9000, rank: -10)

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
          forward_date: Time.utc
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

    describe "#check_text" do
      it "returns true if there is no text" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.check_text(nil, user, message, services).should(be_true)
      end

      it "returns true if message is preformatted" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          preformatted: true,
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.check_text("Example Text", user, message, services).should(be_true)
      end

      it "returns true if text passes checks" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.check_text("Example Text", user, message, services).should(be_true)
      end

      it "returns false if text is not allowed" do
        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "𝐀𝐁𝐂",
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.check_text("𝐀𝐁𝐂", user, message, services).should(be_false)
      end

      it "returns false if text contains codepoints not permitted by Robot9000" do
        r9k_services = create_services(client: client, r9k: MockRobot9000.new)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "🐖",
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.check_text("🐖", user, message, r9k_services).should(be_false)
      end
    end

    describe "#format_text" do
      # TODO: Add tests
      # Attempting to test this function produces a hard to isolate compiler bug
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

        user = SQLiteUser.new(80300, rank: 10)

        unless hash = handler.get_reply_receivers(reply_to, message, user, services)
          fail("Handler method should have returned a hash of reply message receivers")
        end

        hash[20000].should(eq(5))
        hash[60200].should(eq(7))
      end

      it "returns nil if reply does not exist in cache" do
        reply_to = create_message(
          10000,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        user = SQLiteUser.new(80300, rank: 10)

        handler.get_reply_receivers(reply_to, message, user, services).should(be_nil)
      end
    end

    describe "#get_message_receivers" do
      it "returns array of user IDs without given user ID" do
        user = SQLiteUser.new(80300, rank: 10)

        handler.get_message_receivers(user, services).should_not(contain(user.id))
      end

      it "returns array of user IDs including given user if debug is enabled" do
        user = SQLiteUser.new(80300, rank: 10)

        user.toggle_debug

        handler.get_message_receivers(user, services).should(contain(user.id))
      end
    end

    describe "#prepend_pseudonym" do
      it "returns unaltered text and entities if pseudonymous mode is not enabled" do
        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            "underline",
            0,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "strikethrough",
            7,
            4,
          ),
        ]

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000)

        text, entities = handler.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          services
        )

        text.should(eq(message_text))
        entities.should(eq(message_entities))
      end

      it "returns unaltered text and entities if message is preformatted" do
        mock_services = create_services(
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            "underline",
            0,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "strikethrough",
            7,
            4,
          ),
        ]

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: message_text,
          entities: message_entities,
          preformatted: true,
        )

        user = MockUser.new(9000)

        text, entities = handler.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          mock_services
        )

        text.should(eq(message_text))
        entities.should(eq(message_entities))
      end

      it "returns empty text and entities is user has no tripcode" do
        mock_services = create_services(
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            "underline",
            0,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "strikethrough",
            7,
            4,
          ),
        ]

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000)

        text, entities = handler.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          mock_services
        )

        text.should(be_empty)
        entities.should(be_empty)
      end

      it "returns updated entities and text with tripcode header" do
        mock_services = create_services(
          relay: MockRelay.new("", client),
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            "underline",
            0,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "strikethrough",
            7,
            4,
          ),
        ]

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000, tripcode: "User#SecurePassword")

        text, entities = handler.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          mock_services
        )

        expected = "User !JMf3r1v1Aw:\n" \
                   "Example Text"

        text.should(eq(expected))
        entities.size.should(eq(4))

        entities[0].type.should(eq("bold"))
        entities[1].type.should(eq("code"))
        entities[2].type.should(eq("underline"))
        entities[3].type.should(eq("strikethrough"))
      end
    end

    describe "#get_caption_and_entities" do
      it "returns unaltered string and entities if message is preformatted" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          caption: "Preformatted Text ~~Admin",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              25,
            ),
          ],
          preformatted: true,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = handler.get_caption_and_entities(message, user, services)

        text.should(eq("Preformatted Text ~~Admin"))

        entities.size.should(eq(1))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(25))
      end

      it "returns empty text and empty entities when user sends invalid text" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          caption: "𝐀𝐁𝐂"
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = handler.get_caption_and_entities(message, user, services)

        text.should(be_empty)
        entities.should(be_empty)
      end

      it "returns formatted text and updated entities" do
        config = HandlerConfig.new(
          MockConfig.new(
            linked_network: {"foo" => "foochatbot"}
          )
        )

        format_services = create_services(client: client, config: config)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          caption: "Text with entities and backlinks >>>/foo/",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              4,
            ),
            Tourmaline::MessageEntity.new(
              "underline",
              4,
              13,
            ),
            Tourmaline::MessageEntity.new(
              "text_link",
              0,
              25,
              "www.google.com"
            ),
          ],
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        expected = "Text with entities and backlinks >>>/foo/\n" \
                   "(www.google.com)"

        text, entities = handler.get_caption_and_entities(message, user, format_services)

        text.should(eq(expected))
        entities.size.should(eq(2))

        entities[0].type.should(eq("underline"))
        entities[1].type.should(eq("text_link"))
        entities[1].length.should(eq(8)) # >>>/foo/
      end

      it "returns formatted text and updated entities with pseudonym" do
        config = HandlerConfig.new(
          MockConfig.new(
            pseudonymous: true,
            linked_network: {"foo" => "foochatbot"}
          )
        )

        format_services = create_services(client: client, config: config)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "beispiel"),
          caption: "Text with entities and backlinks >>>/foo/",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              4,
            ),
            Tourmaline::MessageEntity.new(
              "underline",
              4,
              13,
            ),
            Tourmaline::MessageEntity.new(
              "text_link",
              0,
              25,
              "www.google.com"
            ),
          ],
        )

        unless user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        expected = "Voorb !JMf3r1v1Aw:\n" \
                   "Text with entities and backlinks >>>/foo/\n" \
                   "(www.google.com)"

        text, entities = handler.get_caption_and_entities(message, user, format_services)

        text.should(eq(expected))
        entities.size.should(eq(4))

        entities[0].type.should(eq("bold"))
        entities[1].type.should(eq("code"))
        entities[2].type.should(eq("underline"))
        entities[3].type.should(eq("text_link"))
        entities[3].length.should(eq(8)) # >>>/foo/
      end
    end

    describe "#r9k_checks" do
      it "returns true if there is no Robot9000 service available" do
        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_checks(user, message, services).should(be_true)
      end

      it "returns false if message fails r9k text check" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_checks(user, message, r9k_services).should(be_true)

        handler.r9k_checks(user, message, r9k_services).should(be_false)
      end

      it "returns false if message fails r9k media check" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_media: true
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_checks(user, message, r9k_services).should(be_true)

        handler.r9k_checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#r9k_forward_checks" do
      it "returns true if there is no Robot9000 service available" do
        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_forward_checks(user, message, services).should(be_true)
      end

      it "returns true if r9k service does not check forwards" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_forward_checks(user, message, r9k_services).should(be_true)
      end

      it "returns false if message fails r9k text check" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_text: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_forward_checks(user, message, r9k_services).should(be_true)

        handler.r9k_forward_checks(user, message, r9k_services).should(be_false)
      end

      it "returns false if message fails r9k media check" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_media: true
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_forward_checks(user, message, r9k_services).should(be_true)

        handler.r9k_forward_checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#r9k_text" do
      it "returns true if there is no Robot9000 service available" do
        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, services).should(be_true)
      end

      it "returns true if Robot900 does not check text" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, r9k_services).should(be_true)
      end

      it "returns false if text is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, r9k_services).should(be_true)

        handler.r9k_text(user, message, r9k_services).should(be_false)
      end

      it "cooldowns user if text is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true,
            cooldown: 10,
          )
        )

        user = MockUser.new(9000, cooldown_until: nil)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, r9k_services)

        user.cooldown_until.should(be_nil)

        handler.r9k_text(user, message, r9k_services)

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if text is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true,
            warn_user: true,
          )
        )

        user = MockUser.new(9000, warnings: 0)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, r9k_services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        handler.r9k_text(user, message, r9k_services)

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "stores line of text if text is original" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        handler.r9k_text(user, message, r9k_services).should(be_true)

        unless r9k = r9k_services.robot9000
          fail("Services should contain a Robot9000 service")
        end

        r9k.as(MockRobot9000).lines.should(contain("example text"))
      end
    end

    describe "#r9k_media" do
      it "returns true if there is no Robot9000 service available" do
        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, services).should(be_true)
      end

      it "returns true if Robot900 does not check media" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, r9k_services).should(be_true)
      end

      it "returns false if media is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, r9k_services).should(be_true)

        handler.r9k_media(user, message, r9k_services).should(be_false)
      end

      it "cooldowns user if media is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_media: true,
            cooldown: 10,
          )
        )

        user = MockUser.new(9000, cooldown_until: nil)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, r9k_services)

        user.cooldown_until.should(be_nil)

        handler.r9k_media(user, message, r9k_services)

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if media is unoriginal" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_media: true,
            warn_user: true,
          )
        )

        user = MockUser.new(9000, warnings: 0)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, r9k_services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        handler.r9k_media(user, message, r9k_services)

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "stores file id if media is original" do
        r9k_services = create_services(
          client: client,
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        handler.r9k_media(user, message, r9k_services).should(be_true)

        unless r9k = r9k_services.robot9000
          fail("Services should contain a Robot9000 service")
        end

        r9k.as(MockRobot9000).files.should(contain("unique_photo"))
      end
    end
  end
end
