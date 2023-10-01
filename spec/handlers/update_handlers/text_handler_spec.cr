require "../../spec_helper.cr"

module PrivateParlorXT
  describe TextHandler do
    client = MockClient.new

    ranks = {
      10 => Rank.new(
        "Mod",
        Set(CommandPermissions).new,
        Set{
          MessagePermissions::Text,
        },
      ),
      -5 => Rank.new(
        "Restricted",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = TextHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if message is a forward" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user")
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "returns early if user is not authorized" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(-5)
        services.database.update_user(user)

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should_not(eq("Example Text"))
      end

      it "returns early if reply message does not exist in message history" do
        reply_to = create_message(
          50,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
          reply_to_message: reply_to
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "queues text message" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ]
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Example Text"))
          msg.entities.size.should(eq(1))
          msg.entities[0].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues text message with reply" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
          reply_to_message: reply_to
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        replies = {
          20000 => 5,
          80300 => 6,
          60200 => 7,
          50000 => nil,
        }

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Example Text"))
          msg.entities.size.should(eq(1))
          msg.entities[0].type.should(eq("underline"))
          msg.reply_to.should(eq(replies[msg.receiver]))

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end
    end

    describe "#spamming?" do
      it "returns true if user is spamming text" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(
          client: client,
          spam: SpamHandler.new(
            spam_limit: 200,
            score_character: 1,
            score_line: 100,
          )
        )

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(
          beispiel,
          message,
          "example",
          spam_services
        )

        unless spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.spamming?(
          beispiel,
          message,
          "example",
          spam_services,
        ).should(be_true)
      end

      it "returns false if user is not spamming text" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        handler.spamming?(
          beispiel,
          message,
          "example",
          spam_services,
        ).should(be_false)
      end

      it "returns false if no spam handler" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spamless_services = create_services(client: client)

        handler.spamming?(
          beispiel,
          message,
          "example",
          spamless_services
        ).should(be_false)
      end

      it "returns false if message is preformatted" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          preformatted: true,
        )

        handler.spamming?(
          beispiel,
          message,
          "example",
          services
        ).should(be_false)
      end
    end

    describe "#get_text_and_entities" do
      it "returns unaltered string and entities if message is preformatted" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Preformatted Text ~~Admin",
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

        text, entities = handler.get_text_and_entities(message, user, services)

        text.should(eq("Preformatted Text ~~Admin"))

        entities.size.should(eq(1))

        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(25))
      end

      it "returns empty text and empty entities when message text is nil" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: nil,
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = handler.get_text_and_entities(message, user, services)

        text.should(be_empty)
        entities.should(be_empty)
      end

      it "returns empty text and empty entities when user is spamming" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "more text"
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        spam_services = create_services(
          client: client,
          spam: SpamHandler.new(
            spam_limit: 200,
            score_character: 1,
            score_line: 100,
          )
        )

        unless spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(
          user,
          message,
          "example",
          spam_services
        )

        text, entities = handler.get_text_and_entities(message, user, spam_services)

        text.should(be_empty)
        entities.should(be_empty)
      end

      it "returns empty text and empty entities when user sends invalid text" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "𝐀𝐁𝐂"
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        text, entities = handler.get_text_and_entities(message, user, services)

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
          text: "Text with entities and backlinks >>>/foo/",
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

        text, entities = handler.get_text_and_entities(message, user, format_services)

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
          text: "Text with entities and backlinks >>>/foo/",
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

        text, entities = handler.get_text_and_entities(message, user, format_services)

        text.should(eq(expected))
        entities.size.should(eq(4))

        entities[0].type.should(eq("bold"))
        entities[1].type.should(eq("code"))
        entities[2].type.should(eq("underline"))
        entities[3].type.should(eq("text_link"))
        entities[3].length.should(eq(8)) # >>>/foo/
      end
    end
  end
end
