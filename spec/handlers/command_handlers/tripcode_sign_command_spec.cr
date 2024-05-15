require "../../spec_helper.cr"

module PrivateParlorXT
  describe TripcodeSignCommand do
    ranks = {
      0 => Rank.new(
        "User",
        Set{
          CommandPermissions::TSign,
        },
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if message is a forward" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign Tripcode sign caption",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "returns early if user has no tripcode" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign Tripcode sign caption",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.no_tripcode_set))
      end

      it "returns early if user is not authorized" do
        handler = TripcodeSignCommand.new(MockConfig.new)

        restricted_ranks = {
          0 => Rank.new(
            "User",
            Set(CommandPermissions).new,
            Set(MessagePermissions).new,
          ),
        }

        restricted_user_services = create_services(
          ranks: restricted_ranks,
          relay: MockRelay.new("", MockClient.new),
        )

        generate_users(restricted_user_services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/tsign   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              6
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              9,
              7
            ),
          ]
        )

        handler.do(message, restricted_user_services)

        messages = restricted_user_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(restricted_user_services.replies.command_disabled))
      end

      it "returns early if text contains invalid characters" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign 𝐀𝐁𝐂",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.rejected_message))
      end

      it "returns early if message has no arguments" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns early if user is spamming" do
        services = create_services(
          ranks: ranks, 
          spam: SpamHandler.new(
            spam_limit: 10, 
            score_animation: 2,
            score_text: 0,
            score_line: 5,
            score_character: 1,
          ),
          relay: MockRelay.new("", MockClient.new)
        )

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign Tripcode sign caption",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        spammy_message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/tsign Tripcode sign text",
        )

        handler.do(spammy_message, services)

        unless updated_message = spammy_message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_falsey)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.spamming))
      end

      it "returns early if message is not unique" do
        services = create_services(
          ranks: ranks, 
          r9k: SQLiteRobot9000.new(
            DB.open("sqlite3://%3Amemory%3A"),
            check_media: true,
          ),
          relay: MockRelay.new("", MockClient.new)
        )

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign Tripcode sign caption",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        unoriginal_message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/tsign Tripcode sign caption",
        )

        handler.do(unoriginal_message, services)

        unless updated_message = unoriginal_message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_falsey)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.unoriginal_message))
      end

      it "updates message contents" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)
    
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
          text: "/tsign   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              6
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              9,
              7
            ),
          ]
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        expected_text = "Voorb !JMf3r1v1Aw:\nExample text"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(2))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(0))
        updated_message.entities[0].length.should(eq(5))

        updated_message.entities[1].type.should(eq("code"))
        updated_message.entities[1].offset.should(eq(6))
        updated_message.entities[1].length.should(eq(11))

        updated_message.preformatted?.should(be_true)
      end
    end

    describe "#spamming?" do
      it "returns true if user is sign spamming" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spam_services = create_services(spam: SpamHandler.new)

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, "", spam_services)

        unless spam.sign_last_used[beispiel.id]?
          fail("Expiration time should not be nil")
        end

        handler.spamming?(beispiel, message, "", spam_services).should(be_true)
      end

      it "returns true if user is spamming text" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spam_services = create_services(spam: SpamHandler.new(
          spam_limit: 10,
          score_character: 1,
          score_line: 0,
          score_text: 1
        ))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, "Example", spam_services)

        unless spam.scores[beispiel.id]?
          fail("Score should not be nil")
        end

        handler.spamming?(beispiel, message, "Example", spam_services).should(be_true)
      end

      it "returns false if user is not sign spamming" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spam_services = create_services(spam: SpamHandler.new)

        handler.spamming?(beispiel, message, "", spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = TripcodeSignCommand.new(MockConfig.new)
        
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end
  end
end
