require "../spec_helper.cr"

module PrivateParlorXT
  describe Format do
    describe "#substitute_message" do
      it "globally substitutes placeholders" do
        placeholder_text = "User {id} sent a {type} message [{message_id}] (origin: {message_id})"

        parameters = {
          "id"         => 9000.to_s,
          "message_id" => 20.to_s,
        }

        expected = "User 9000 sent a  message [20] (origin: 20)"

        Format.substitute_message(placeholder_text, parameters).should(eq(expected))
      end
    end

    describe "#substitute_reply" do
      it "globally substitutes placeholders and escapes MarkdownV2" do
        placeholder_text = "User {id} sent a {type} message [{message_id}] (origin: {message_id}, karma: {karma})"

        parameters = {
          "id"         => 9000.to_s,
          "message_id" => 20.to_s,
          "karma"      => 2.0.to_s,
        }

        expected = "User 9000 sent a  message [20] (origin: 20, karma: 2\\.0)"

        Format.substitute_reply(placeholder_text, parameters).should(eq(expected))
      end
    end

    describe "#check_text" do
      it "returns true if message is preformatted" do
        services = create_services()

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          caption: "Example Text",
          from: bot_user,
        )

        message.preformatted = true

        user = MockUser.new(9000, rank: 0)

        Format.check_text("Example Text", user, message, services).should(be_true)
      end

      it "returns true if text passes checks" do
        services = create_services()

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          caption: "Example Text",
          from: bot_user,
        )

        user = MockUser.new(9000, rank: 0)

        Format.check_text("Example Text", user, message, services).should(be_true)
      end

      it "returns false if text is not allowed" do
        services = create_services()

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          caption: "𝐀𝐁𝐂",
          from: bot_user,
        )

        user = MockUser.new(9000, rank: 0)

        Format.check_text("𝐀𝐁𝐂", user, message, services).should(be_false)
      end

      it "returns false if text contains codepoints not permitted by Robot9000" do
        r9k_services = create_services(r9k: MockRobot9000.new)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          caption: "🐖",
          from: bot_user,
        )

        user = MockUser.new(9000, rank: 0)

        Format.check_text("🐖", user, message, r9k_services).should(be_false)
      end
    end

    describe "#format_text" do
      it "returns unaltered text and entities if message is preformatted" do
        services = create_services()

        text = "Example text ~~Admin"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 8,
            length: 4,
            url: "www.example.com"
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 13,
            length: 7,
          ),
        ]

        tuple = Format.format_text(text, entities, true, services)

        tuple[0].should(eq(text))
        tuple[1].should(eq(entities))
      end

      it "returns formatted text and entities" do
        services = create_services()

        text = "Example text ~~Admin"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 8,
            length: 4,
            url: "www.example.com"
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 13,
            length: 7,
          ),
        ]

        expected_tuple = Format.strip_format(text, entities, services.config.entity_types, services.config.linked_network)

        tuple = Format.format_text(text, entities, false, services)

        tuple.should(eq(expected_tuple))
      end
    end

    describe "#text_and_entities" do
      it "returns unaltered string and entities if message is preformatted" do
        services = create_services()
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "🐖",
          from: tourmaline_user,
        )

        message.preformatted = true

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          caption: "Preformatted Text ~~Admin",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 25,
            ),
          ],
        )

        message.preformatted = true

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = Format.text_and_entities(message, user, services)

        text.should(eq("Preformatted Text ~~Admin"))

        entities.size.should(eq(1))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(25))
      end

      it "returns nil and empty entities when user sends invalid text" do
        services = create_services()
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          caption: "𝐀𝐁𝐂"
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = Format.text_and_entities(message, user, services)

        text.should(be_nil)
        entities.should(be_empty)
      end

      it "returns formatted text and updated entities" do
        services = create_services()
        generate_users(services.database)

        config = HandlerConfig.new(
          MockConfig.new(
            linked_network: {"foo" => "foochatbot"}
          )
        )

        format_services = create_services(config: config)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          caption: "Text with entities and backlinks >>>/foo/",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 4,
            ),
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 4,
              length: 13,
            ),
            Tourmaline::MessageEntity.new(
              type: "text_link",
              offset: 0,
              length: 25,
              url:  "www.google.com"
            ),
          ],
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        expected = "Text with entities and backlinks >>>/foo/\n" \
                   "(www.google.com)"

        text, entities = Format.text_and_entities(message, user, format_services)

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

        format_services = create_services(config: config)

        generate_users(format_services.database)

        tourmaline_user = Tourmaline::User.new(60200, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "Text with entities and backlinks >>>/foo/",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 4,
            ),
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 4,
              length: 13,
            ),
            Tourmaline::MessageEntity.new(
              type: "text_link",
              offset: 0,
              length: 25,
              url:  "www.google.com"
            ),
          ],
        )

        unless user = format_services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        expected = "Voorb !JMf3r1v1Aw:\n" \
                   "Text with entities and backlinks >>>/foo/\n" \
                   "(www.google.com)"

        text, entities = Format.text_and_entities(message, user, format_services)

        text.should(eq(expected))
        entities.size.should(eq(4))

        entities[0].type.should(eq("bold"))
        entities[1].type.should(eq("code"))
        entities[2].type.should(eq("underline"))
        entities[3].type.should(eq("text_link"))
        entities[3].length.should(eq(8)) # >>>/foo/
      end
    end

    describe "#validate_text_and_entities" do
      it "returns nil and empty entities when user sends invalid text" do
        services = create_services()
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          caption: "𝐀𝐁𝐂"
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = Format.text_and_entities(message, user, services)

        text.should(be_nil)
        entities.should(be_empty)
      end

      it "returns the given message's text and entities" do
        services = create_services()

        generate_users(services.database)

        config = HandlerConfig.new(
          MockConfig.new(
            linked_network: {"foo" => "foochatbot"}
          )
        )

        format_services = create_services(config: config)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          caption: "Text with entities and backlinks >>>/foo/",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 4,
            ),
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 4,
              length: 13,
            ),
            Tourmaline::MessageEntity.new(
              type: "text_link",
              offset: 0,
              length: 25,
              url:  "www.google.com"
            ),
          ],
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        expected = "Text with entities and backlinks >>>/foo/"

        text, entities = Format.validate_text_and_entities(message, user, format_services)

        text.should(eq(expected))
        entities.size.should(eq(3))

        entities[0].type.should(eq("bold"))
        entities[1].type.should(eq("underline"))
        entities[2].type.should(eq("text_link"))
      end
    end

    describe "#prepend_pseudonym" do
      it "returns unaltered text and entities if pseudonymous mode is not enabled" do
        services = create_services()

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
        ]

        bot_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000)

        text, entities = Format.prepend_pseudonym(
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
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
        ]

        bot_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: message_text,
          entities: message_entities,
        )

        message.preformatted = true

        user = MockUser.new(9000)

        text, entities = Format.prepend_pseudonym(
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
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
        ]

        bot_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000)

        text, entities = Format.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          mock_services
        )

        text.should(be_nil)
        entities.should(be_empty)
      end

      it "returns updated entities and text with tripcode header" do
        mock_services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
        ]

        bot_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000, tripcode: "User#SecurePassword")

        text, entities = Format.prepend_pseudonym(
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

      it "returns updated entities and text with flag header" do
        mock_services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              pseudonymous: true,
              flag_signatures: true,
            )
          )
        )

        message_text = "Example Text"
        message_entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
        ]

        bot_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: message_text,
          entities: message_entities,
        )

        user = MockUser.new(9000, tripcode: "🦤🦆🕊️#DoDuDo")

        text, entities = Format.prepend_pseudonym(
          message_text,
          message_entities,
          user,
          message,
          mock_services
        )

        expected = "🦤🦆🕊️:\n" \
                   "Example Text"

        text.should(eq(expected))
        entities.size.should(eq(3))

        entities[0].type.should(eq("code"))
        entities[1].type.should(eq("underline"))
        entities[2].type.should(eq("strikethrough"))
      end
    end

    describe "#cooldown_until" do
      it "returns cooldown time response" do
        services = create_services

        time = Time.utc

        expected = "#{services.replies.cooldown_true} #{Format.time(time, services.locale.time_format)}"

        result = Format.cooldown_until(time, services.locale, services.replies)

        result.should(eq(expected))
      end

      it "returns a no cooldown response if time is nil" do
        services = create_services

        result = Format.cooldown_until(nil, services.locale, services.replies)

        result.should(eq(services.replies.cooldown_false))
      end
    end

    describe "#warn_expiry" do
      it "returns warning expiration response" do
        services = create_services

        time = Time.utc

        expected = Format.substitute_message(services.replies.info_warning, {
          "warn_expiry" => Format.time(time, services.locale.time_format)
        })

        result = Format.warn_expiry(time, services.locale, services.replies)

        result.should(eq(expected))
      end

      it "returns nil if expiration time is nil" do
        services = create_services

        result = Format.warn_expiry(nil, services.locale, services.replies)

        result.should(be_nil)
      end
    end

    describe "#tripcode_set" do
      it "returns tripcode set reponse" do
        services = create_services

        expected = Format.substitute_message(services.replies.tripcode_set, {
          "set_format" => Format.substitute_reply(services.replies.tripcode_set_format, {
            "name" => "name",
            "tripcode" => "!ozOtJW9BFA",
          })
        })

        result = Format.tripcode_set(
          services.replies.tripcode_set_format,
          "name",
          "!ozOtJW9BFA",
          services.replies
        )

        result.should(eq(expected))
      end
    end

    describe "#reason" do
      it "returns formatted reason reply" do
        services = create_services

        expected = "#{services.replies.reason_prefix}reason"

        result = Format.reason("reason", services.replies)

        result.should(eq(expected))
      end

      it "returns nil if reason is nil" do 
        services = create_services

        result = Format.reason(nil, services.replies)

        result.should(be_nil)
      end
    end

    describe "#truncate_karma_reason" do
      it "returns first 500 characters of karma reason" do
        services = create_services

        reason = "lorem sed risus ultricies tristique nulla aliquet enim tortor at auctor
        urna nunc id cursus metus aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices
        sagittis orci a scelerisque purus semper eget duis at tellus at urna condimentum mattis pellentesque id nibh tortor
        id aliquet lectus proin nibh nisl condimentum id venenatis a condimentum vitae sapien pellentesque habitant morbi
        tristique senectus et netus et malesuada fames ac turpis egestas sed tempus urna et pharetra pharetra massa massa
        ultricies mi quis hendrerit dolor magna eget est lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque
        habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas integer eget aliquet nibh praesent
        tristique magna sit amet purus gravida quis blandit turpis cursus in hac habitasse platea dictumst quisque sagittis"

        expected = "lorem sed risus ultricies tristique nulla aliquet enim tortor at auctor
        urna nunc id cursus metus aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices
        sagittis orci a scelerisque purus semper eget duis at tellus at urna condimentum mattis pellentesque id nibh tortor
        id aliquet lectus proin nibh nisl condimentum id venenatis a condimentum vitae sapien pellentesque habitant morbi
        tristique senectus et netus et malesuada fames ac turpis egestas sed temp"

        unless result = Format.truncate_karma_reason(reason)
          fail("truncate_karma_reason should have returned a result")
        end

        result.should(eq(expected))
        result.size.should(eq(500))
      end

      it "returns nil if karma reason is nil" do
        services = create_services

        result = Format.truncate_karma_reason(nil)

        result.should(be_nil)
      end
    end

    describe "#karma_reason" do
      it "returns formatted karma reply with reason" do
        services = create_services

        reply = "Karma vote with reason{karma_reason}"

        reason = "lorem sed risus\n" \
                 "ultricies tristique nulla\n" \
                 "aliquet enim tortor at auctor"

        expected = "Karma vote with reason\\ for:\n" \
                   ">lorem sed risus\n" \
                   ">ultricies tristique nulla\n" \
                   ">aliquet enim tortor at auctor"

        result = Format.karma_reason(reason, reply, services.replies)

        result.should(eq(expected))
      end

      it "returns karma reply if reason is nil or empty" do
        services = create_services

        expected = Format.substitute_reply(services.replies.gave_upvote, {} of String => String)

        result = Format.karma_reason(nil, services.replies.gave_upvote, services.replies)
        result.should(eq(expected))

        result_two = Format.karma_reason("", services.replies.gave_upvote, services.replies)
        result_two.should(eq(expected))

        result_three = Format.karma_reason("\\\\\\\\", services.replies.gave_upvote, services.replies)
        result_three.should(eq(expected))
      end
    end

    describe "#reason_log" do
      it "returns formatted reason reply" do
        services = create_services

        expected = "#{services.logs.reason_prefix}reason"

        result = Format.reason_log("reason", services.logs)

        result.should(eq(expected))
      end

      it "returns nil if reason is nil" do 
        services = create_services

        result = Format.reason_log(nil, services.logs)

        result.should(be_nil)
      end
    end

    describe "#strip_format" do
      it "returns text and entities stripped of formatting" do
        services = create_services

        text = "Example text with >>>/foo/ backlinks"
        entities = [
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 0,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "strikethrough",
            offset: 7,
            length: 4,
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 13,
            length: 4,
            url: "www.google.com"
          ),
        ]

        expected = "Example text with >>>/foo/ backlinks\n"\
                   "(www.google.com)"

        result_text, result_entities = Format.strip_format(
          text,
          entities,
          ["strikethrough"],
          {"foo" => "foochatbot"}
        )

        result_text.should(eq(expected))

        result_entities.size.should(eq(3))

        result_entities[0].type.should(eq("underline"))
        result_entities[1].type.should(eq("text_link"))
        result_entities[2].type.should(eq("text_link"))
        result_entities[2].length.should(eq(8))
      end
    end

    describe "#remove_entities" do
      it "removes only the given entity types" do
        strip_types = ["bold", "text_link"]

        entities = [
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 3,
            length: 4,
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 10,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 10,
            length: 7,
            url: "https://crystal-lang.org",
          ),
          Tourmaline::MessageEntity.new(
            type: "italic",
            offset: 20,
            length: 4,
          ),
        ]

        updated_entities = Format.remove_entities(entities, strip_types)

        updated_entities.should_not(eq(entities))
        updated_entities.size.should(eq(1))
        updated_entities[0].should(eq(entities[3]))
      end
    end

    describe "#generate_tripcode" do
      it "generates 8chan secure tripcodes" do
        salt_services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              salt: "ASecureSalt"
            )
          )
        )

        Format.generate_tripcode("name#password", salt_services).should(eq({"name", "!tOi2ytmic0"}))
        Format.generate_tripcode("example#1", salt_services).should(eq({"example", "!8KD/BUYBBu"}))
        Format.generate_tripcode("example#pass", salt_services).should(eq({"example", "!LhfgvU61/K"}))
      end

      it "generates 2channel tripcodes" do
        services = create_services()
        Format.generate_tripcode("name#password", services).should(eq({"name", "!ozOtJW9BFA"}))
        Format.generate_tripcode("example#1", services).should(eq({"example", "!tsGpSwX8mo"}))
        Format.generate_tripcode("example#pass", services).should(eq({"example", "!XksB4AwhxU"}))

        Format.generate_tripcode(
          "example#AnExcessivelyLongTripcodePassword", services
        ).should(eq({"example", "!v8ZIGlF0Uc"}))
        Format.generate_tripcode(
          "example#AnExcess", services
        ).should(eq({"example", "!v8ZIGlF0Uc"}))
      end
    end

    describe "#replace_links" do
      it "appends text links to string" do
        text = "Text link example"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 5,
            length: 4,
            url: "www.example.com",
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 10,
            length: 7,
            url: "https://crystal-lang.org",
          ),
        ]

        expected = "Text link example\n" \
                   "(www.example.com)\n" \
                   "(https://crystal-lang.org)"

        Format.replace_links(text, entities).should(eq(expected))
      end
    end

    describe "#format_network_links" do
      it "only formats chats in linked network" do
        network = {
          "foo"  => "foochatbot",
          "fizz" => "fizzchatbot",
        }

        text = "Backlinks: >>>/foo/ >>>/bar/ >>>/fizz/"

        entities = Format.format_network_links(text, [] of Tourmaline::MessageEntity, network)

        entities.size.should(eq(2))

        unless entities[0].url
          fail("Backlink entities should contain a url")
        end

        unless entities[1].url
          fail("Backlink entities should contain a url")
        end

        entities[0].type.should(eq("text_link"))
        entities[0].length.should(eq(8))
        entities[0].offset.should(eq(11))
        entities[0].url.should(eq("tg://resolve?domain=foochatbot"))

        entities[1].type.should(eq("text_link"))
        entities[1].length.should(eq(9))
        entities[1].offset.should(eq(29))
        entities[1].url.should(eq("tg://resolve?domain=fizzchatbot"))
      end

      it "handles UTF-16 codepoints in text" do
        network = {
          "foo"  => "foochatbot",
          "fizz" => "fizzchatbot",
        }

        text = "Backlinks: >>>/foo/ 🔁 >>>/fizz/"

        entities = Format.format_network_links(text, [] of Tourmaline::MessageEntity, network)

        entities.size.should(eq(2))

        unless entities[0].url
          fail("Backlink entities should contain a url")
        end

        unless entities[1].url
          fail("Backlink entities should contain a url")
        end

        entities[0].type.should(eq("text_link"))
        entities[0].length.should(eq(8))
        entities[0].offset.should(eq(11))
        entities[0].url.should(eq("tg://resolve?domain=foochatbot"))

        entities[1].type.should(eq("text_link"))
        entities[1].length.should(eq(9))
        entities[1].offset.should(eq(23))
        entities[1].url.should(eq("tg://resolve?domain=fizzchatbot"))
      end
    end

    describe "#allow_text?" do
      it "returns true if there is no text" do
        Format.allow_text?("").should(be_true)
      end

      it "returns true if text is allowed" do
        Format.allow_text?("example text").should(be_true)
      end

      it "returns false if text is not allowed" do
        Format.allow_text?("𝐀𝐁𝐂").should(be_false)
      end
    end

    describe "#get_arg" do
      it "returns the string that follows the first whitespace in text" do
        command = "/test something"

        expected = "something"

        Format.get_arg(command).should(eq(expected))
      end

      it "returns nil if there is no arg" do
        Format.get_arg("/test").should(be_nil)
      end

      it "returns nil if there is no given text" do
        Format.get_arg(nil).should(be_nil)
      end
    end

    describe "#get_args" do
      it "returns an array of strings that follow the first whitespace in text" do
        command = "/test do something special"

        count_one = ["do something special"]
        count_two = ["do", "something special"]
        count_three = ["do", "something", "special"]

        Format.get_args(command, 1).should(eq(count_one))
        Format.get_args(command, 2).should(eq(count_two))
        Format.get_args(command, 3).should(eq(count_three))
        Format.get_args(command, 4).should(eq(count_three))
      end

      it "returns an empty array if there is no arg" do
        unless result = Format.get_args("/test", 1)
          fail("Result should not be nil")
        end

        result.should(be_empty)
      end

      it "returns nil if there is no given text" do
        Format.get_args(nil, 1).should(be_nil)
      end
    end

    describe "#regular_forward?" do
      it "returns true if message is a regular forward" do
        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 0,
            length: 19,
          ),
        ]

        Format.regular_forward?(text, entities).should(be_true)
      end

      it "returns false if message is not a regular forward" do
        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "italic",
            offset: 0,
            length: 19,
          ),
        ]

        Format.regular_forward?(text, entities).should(be_false)
      end

      it "returns nil if given no entities" do
        text = "Forwarded from User"

        Format.regular_forward?(text, [] of Tourmaline::MessageEntity).should(be_nil)
      end

      it "returns nil if given no text" do
        Format.regular_forward?(nil, [] of Tourmaline::MessageEntity).should(be_nil)
      end
    end

    describe "#forward_header" do
      it "returns header and entities for forwards from users with public forwards" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(
              9000,
              is_bot: false,
              first_name: "example",
              last_name: nil,
            )
          )
        )

        header, entities = Format.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from example\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(22))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(7))
        entities[1].url.should(eq("tg://user?id=9000"))
      end

      it "returns header and entities for forwards from Telegram bots" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(
              9000,
              is_bot: true,
              first_name: "ExampleBot",
              last_name: nil,
              username: "example_bot"
            )
          )
        )

        header, entities = Format.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from ExampleBot\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(25))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(10))
        entities[1].url.should(eq("tg://resolve?domain=example_bot"))
      end

      it "returns header and entities for forwards from public channels" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginChannel.new(
            "channel",
            Time.utc,
            Tourmaline::Chat.new(
              9000,
              type: "channel",
              title: "Example Channel",
              username: "ExamplesChannel"
            ),
            200_i64,
          )
        )

        header, entities = Format.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Example Channel\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(30))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(15))
        entities[1].url.should(eq("tg://resolve?domain=ExamplesChannel&post=200"))
      end

      it "returns header and entities for forwards from private channels" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginChannel.new(
            "channel",
            Time.utc,
            Tourmaline::Chat.new(
              -1009000,
              type: "private",
              title: "Private Example Channel",
            ),
            200_i64,
          )
        )

        header, entities = Format.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private Example Channel\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(38))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(23))
        entities[1].url.should(eq("tg://privatepost?channel=9000&post=200"))
      end

      it "returns header and entities in italics for forwards from users with private forwards" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginHiddenUser.new(
            "hidden_user",
            Time.utc,
            "Private User"
          )
        )

        header, entities = Format.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private User\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(27))

        entities[1].type.should(eq("italic"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(12))
      end
    end

    describe "#user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.user_forward(
          "Dodo 🦤🏝🍽",
          9000,
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Dodo 🦤🏝🍽\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(26))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(11))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(28))
        entities[2].length.should(eq(10))
      end
    end

    describe "#private_user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.private_user_forward(
          "Private 🔒🦤 Dodo",
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private 🔒🦤 Dodo\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(32))

        entities[1].type.should(eq("italic"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(17))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(34))
        entities[2].length.should(eq(10))
      end
    end

    describe "#username_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.username_forward(
          "🤖 Dodo Bot 🦤",
          "dodobot",
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from 🤖 Dodo Bot 🦤\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(29))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(14))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(31))
        entities[2].length.should(eq(10))
      end
    end

    describe "#private_channel_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.private_channel_forward(
          "🦤 Private 🔒 Dodo 📣",
          9000,
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from 🦤 Private 🔒 Dodo 📣\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(36))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(21))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(38))
        entities[2].length.should(eq(10))
      end
    end

    describe "#user_reveal" do
      it "returns Markdown link to the given user id" do
        services = create_services

        expected = "[user\\_name](tg://user?id=123456)"

        expected = Format.substitute_message(services.replies.username_reveal, {
          "username" => expected,
        })

        result = Format.user_reveal(123456, "user_name", services.replies)

        result.should(eq(expected))
      end
    end

    describe "#user_sign" do
      it "returns updated entities and text signed with user name" do
        arg = "Example🦫Text"

        expected_text = "Example🦫Text ~~🦫Beaver"

        text, entities = Format.user_sign(
          "🦫Beaver",
          123456,
          arg,
          [] of Tourmaline::MessageEntity
        )

        text.should(eq(expected_text))

        entities.size.should(eq(1))

        entities[0].type.should(eq("text_link"))
        entities[0].offset.should(eq(14))
        entities[0].length.should(eq(10))
      end
    end

    describe "#karma_sign" do
      it "returns updated entities and text signed with karma level" do
        arg = "Example🦫Text"

        expected_text = "Example🦫Text t. 🦫-Tier"

        text, entities = Format.karma_sign(
          "🦫-Tier",
          arg,
          [] of Tourmaline::MessageEntity
        )

        text.should(eq(expected_text))

        entities.size.should(eq(2))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(14))
        entities[0].length.should(eq(10))

        entities[1].type.should(eq("italic"))
        entities[1].offset.should(eq(14))
        entities[1].length.should(eq(10))
      end
    end

    describe "#tripcode_sign" do
      it "returns header with updated entities and text for a tripcode" do
        expected_header = "🦫Beaver !Tripcode:\n"

        text, entities = Format.tripcode_sign(
          "🦫Beaver",
          "!Tripcode",
          [] of Tourmaline::MessageEntity
        )

        text.should(eq(expected_header))

        entities.size.should(eq(2))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(8))

        entities[1].type.should(eq("code"))
        entities[1].offset.should(eq(9))
        entities[1].length.should(eq(9))
      end
    end
    
    describe "#flag_sign" do
      it "returns header with updated entities and text for user flags" do
        expected_header = "🦤🦆🕊️:\n"

        text, entities = Format.flag_sign(
          "🦤🦆🕊️",
          [] of Tourmaline::MessageEntity
        )

        text.should(eq(expected_header))

        entities.size.should(eq(1))

        entities[0].type.should(eq("code"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(7))
      end
    end

    describe "#ranksay" do
      it "returns updated entities and text signed with karma level" do
        arg = "Example🦫Text"

        expected_text = "Example🦫Text ~~🦫Baron"

        text, entities = Format.ranksay(
          "🦫Baron",
          arg,
          [] of Tourmaline::MessageEntity
        )

        text.should(eq(expected_text))

        entities.size.should(eq(1))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(14))
        entities[0].length.should(eq(9))
      end
    end

    describe "#offset_entities" do
      it "adds offset to each entity's offset field" do
        entities = [
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 3,
            length: 4,
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 10,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 10,
            length: 7,
            url: "https://crystal-lang.org",
          ),
          Tourmaline::MessageEntity.new(
            type: "italic",
            offset: 20,
            length: 4,
          ),
        ]

        updated_entities = Format.offset_entities(entities, 10)

        updated_entities[0].offset.should(eq(13))
        updated_entities[1].offset.should(eq(20))
        updated_entities[2].offset.should(eq(20))
        updated_entities[3].offset.should(eq(30))
      end
    end

    describe "#reset_entities" do
      it "subtracts offset from each entity's offset field" do
        entities = [
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 3,
            length: 4,
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 10,
            length: 7,
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 10,
            length: 7,
            url: "https://crystal-lang.org",
          ),
          Tourmaline::MessageEntity.new(
            type: "italic",
            offset: 20,
            length: 4,
          ),
        ]

        updated_entities = Format.reset_entities(entities, 3)

        updated_entities[0].offset.should(eq(0))
        updated_entities[1].offset.should(eq(7))
        updated_entities[2].offset.should(eq(7))
        updated_entities[3].offset.should(eq(17))
      end
    end

    describe "#contact" do
      it "returns formatted contact string" do
        services = create_services

        contact = "@example"

        expected = Format.substitute_message(services.replies.blacklist_contact, {
          "contact" => contact,
        })

        Format.contact(contact, services.replies).should(eq(expected))
      end

      it "returns nil if no contact was given" do
        services = create_services


        Format.contact(nil, services.replies).should(be_nil)
      end
    end

    describe "#time_span" do
      it "returns time and its unit for the given time span" do
        services = create_services

        time_one = 135.5.days
        time_two = 0.5.weeks
        time_three = 65.hours
        time_four = 13.6.hours
        time_five = 56.8.minutes
        time_six = 2.5.seconds

        expected_one = "19#{services.locale.time_units[0]}"
        expected_two = "3#{services.locale.time_units[1]}"
        expected_three = "2#{services.locale.time_units[1]}"
        expected_four = "13#{services.locale.time_units[2]}"
        expected_five = "56#{services.locale.time_units[3]}"
        expected_six = "2#{services.locale.time_units[4]}"

        Format.time_span(time_one, services.locale).should(eq(expected_one))
        Format.time_span(time_two, services.locale).should(eq(expected_two))
        Format.time_span(time_three, services.locale).should(eq(expected_three))
        Format.time_span(time_four, services.locale).should(eq(expected_four))
        Format.time_span(time_five, services.locale).should(eq(expected_five))
        Format.time_span(time_six, services.locale).should(eq(expected_six))
      end
    end

    describe "#smiley" do
      it "returns smiley face based on number of given warnings" do
        smileys = [":)", ":O", ":/", ">:("]

        Format.smiley(0, smileys).should(eq(":)"))
        Format.smiley(1, smileys).should(eq(":O"))
        Format.smiley(2, smileys).should(eq(":O"))
        Format.smiley(3, smileys).should(eq(":/"))
        Format.smiley(4, smileys).should(eq(":/"))
        Format.smiley(5, smileys).should(eq(":/"))
        Format.smiley(6, smileys).should(eq(">:("))
        Format.smiley(7, smileys).should(eq(">:("))
      end
    end

    describe "#karma_loading_bar" do
      it "returns full bar when percentage is 100%" do
        services = create_services()

        expected = services.locale.loading_bar[2] * 10

        bar = Format.karma_loading_bar(100.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns empty bar when percentage is 0%" do
        services = create_services()

        expected = services.locale.loading_bar[0] * 10

        bar = Format.karma_loading_bar(0.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns bar with a half filled pip when percentage is 55%" do
        services = create_services()

        expected = services.locale.loading_bar[2] * 5
        expected = expected + services.locale.loading_bar[1]
        expected = expected + services.locale.loading_bar[0] * 4

        bar = Format.karma_loading_bar(55.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns partially filled bar when percentage has a remainder less than 5" do
        services = create_services()

        expected = services.locale.loading_bar[2] * 3
        expected = expected + services.locale.loading_bar[0] * 7

        bar = Format.karma_loading_bar(33.3_f32, services.locale)

        bar.should(eq(expected))
      end
    end

    describe "#time" do
      it "returns time string based on the given format" do
        time = Time.utc

        format = "%D, %T"

        expected = time.to_s(format)

        Format.time(time, format).should(eq(expected))
      end

      it "returns nil when no time was given" do
        Format.time(nil, "%D, %T").should(be_nil)
      end
    end

    describe "#version" do
      it "returns string containing source code link and information" do 
        expected = "Private Parlor XT vspec \\~ [\\[Source\\]](https://github.com/Private-Parlor/Private-Parlor-XT)"

        Format.version.should(eq(expected))
      end
    end

    describe "#help" do
      it "returns dynamically generated help message according to user's rank" do
        services = create_services
        
        user = MockUser.new(9000, rank: 1000)

        expected = "#{services.replies.help_header}\n" \
                   "#{Format.escape_md("/start - #{services.command_descriptions.start}\n", version: 2)}" \
                   "#{Format.escape_md("/stop - #{services.command_descriptions.stop}\n", version: 2)}" \
                   "#{Format.escape_md("/info - #{services.command_descriptions.info}\n", version: 2)}" \
                   "#{Format.escape_md("/users - #{services.command_descriptions.users}\n", version: 2)}" \
                   "#{Format.escape_md("/version - #{services.command_descriptions.version}\n", version: 2)}" \
                   "#{Format.escape_md("/toggle_karma - #{services.command_descriptions.toggle_karma}\n", version: 2)}" \
                   "#{Format.escape_md("/toggle_debug - #{services.command_descriptions.toggle_debug}\n", version: 2)}" \
                   "#{Format.escape_md("/tripcode - #{services.command_descriptions.tripcode}\n", version: 2)}" \
                   "#{Format.escape_md("/motd - #{services.command_descriptions.motd}\n", version: 2)}" \
                   "#{Format.escape_md("/help - #{services.command_descriptions.help}\n", version: 2)}" \
                   "#{Format.escape_md("/stats - #{services.command_descriptions.stats}\n", version: 2)}" \
                   "\n#{Format.substitute_reply(services.replies.help_rank_commands, {"rank" => "Host"})}\n" \
                   "#{Format.escape_md("/hostsay [text] - #{services.command_descriptions.ranksay}\n", version: 2)}" \
                   "#{Format.escape_md("/adminsay [text] - #{services.command_descriptions.ranksay}\n", version: 2)}" \
                   "#{Format.escape_md("/modsay [text] - #{services.command_descriptions.ranksay}\n", version: 2)}" \
                   "#{Format.escape_md("/purge - #{services.command_descriptions.purge}\n", version: 2)}" \
                   "#{Format.escape_md("/promote [name/OID/ID] [rank] - #{services.command_descriptions.promote}\n", version: 2)}" \
                   "#{Format.escape_md("/demote [name/OID/ID] [rank] - #{services.command_descriptions.demote}\n", version: 2)}" \
                   "\n#{services.replies.help_reply_commands}\n" \
                   "#{Format.escape_md("+1 - #{services.command_descriptions.upvote}\n", version: 2)}" \
                   "#{Format.escape_md("-1 - #{services.command_descriptions.downvote}\n", version: 2)}" 

        result = Format.help(user, services.access.ranks, services, services.command_descriptions, services.replies)

        result.should(eq(expected))
      end
    end
  end
end
