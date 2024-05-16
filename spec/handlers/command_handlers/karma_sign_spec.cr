require "../../spec_helper.cr"

module PrivateParlorXT
  describe KarmaSignCommand do
    describe "#do" do
      it "returns early if message is a forward" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign   Example text",
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

      it "returns early if there are no karma levels" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String)
          )
        )

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign Karma level sign",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "returns early if text contains invalid characters" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign 𝐀𝐁𝐂",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.rejected_message))
      end

      it "returns early if message has no arguments" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.missing_args))
      end

      it "returns early if user is spamming" do
        services = create_services(
          
          spam: SpamHandler.new(
            spam_limit: 10, 
            score_animation: 2,
            score_text: 0,
            score_line: 5,
            score_character: 1,
          ),
        )

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign   Example text",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        spammy_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign   Example text",
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
          
          r9k: SQLiteRobot9000.new(
            DB.open("sqlite3://%3Amemory%3A"),
            check_media: true,
          ),
        )

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign   Example text",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        unoriginal_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign   Example text",
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
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)
    
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bot_command",
              offset: 0,
              length: 6,
            ),
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 9,
              length: 7,
            ),
          ]
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        expected_text = "Example text t. Normal"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(2))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(13))
        updated_message.entities[0].length.should(eq(9))

        updated_message.entities[1].type.should(eq("italic"))
        updated_message.entities[1].offset.should(eq(13))
        updated_message.entities[1].length.should(eq(9))

        updated_message.preformatted?.should(be_true)
      end
    end

    describe "#spamming?" do
      it "returns true if user is sign spamming" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign Example",
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
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign Example",
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
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign Example",
        )

        spam_services = create_services(spam: SpamHandler.new)

        handler.spamming?(beispiel, message, "", spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)
        
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/ksign Example",
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end

    describe "#get_karma_level" do
      it "returns karma level according to user's karma" do
        services = create_services()

        handler = KarmaSignCommand.new(MockConfig.new)

        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: -50),
        ).should(eq("Junk"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: -9),
        ).should(eq("Junk"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 5),
        ).should(eq("Normal"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 12),
        ).should(eq("Common"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 25),
        ).should(eq("Uncommon"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 39),
        ).should(eq("Rare"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 44),
        ).should(eq("Legendary"))
        handler.get_karma_level(
          services.config.karma_levels,
          MockUser.new(1000, karma: 55),
        ).should(eq("Unique"))
      end
    end
  end
end
