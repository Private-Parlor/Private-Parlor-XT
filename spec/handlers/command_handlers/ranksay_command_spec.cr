require "../../spec_helper.cr"

module PrivateParlorXT
  describe RanksayCommand do
    ranks = {
      1000 => Rank.new(
        "Host",
        Set{
          CommandPermissions::RanksayLower,
        },
        Set(MessagePermissions).new,
      ),
      10 => Rank.new(
        "User",
        Set{
          CommandPermissions::Ranksay,
        },
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if message is a forward" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

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
          caption: "/ranksay   Example text",
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

      it "returns early if user is not authorized" do
        handler = RanksayCommand.new(MockConfig.new)

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
          text: "/ranksay   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              6
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              8,
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

        handler = RanksayCommand.new(MockConfig.new)

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
          caption: "/ranksay 𝐀𝐁𝐂",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.rejected_message))
      end

      it "returns early if message has no arguments" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

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
          caption: "/ranksay",
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
            score_text: 0,
            score_line: 2,
            score_character: 1,
          ),
          relay: MockRelay.new("", MockClient.new)
        )

        handler = RanksayCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay   Example",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        spammy_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay   Example text",
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

        handler = RanksayCommand.new(MockConfig.new)

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
          caption: "/ranksay   Example text",
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        updated_message.preformatted?.should(be_true)

        unoriginal_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          caption: "/ranksay   Example text",
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

        handler = RanksayCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              8
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              11,
              7
            ),
          ]
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        expected_text = "Example text ~~User"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(1))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(13))
        updated_message.entities[0].length.should(eq(6))

        updated_message.preformatted?.should(be_true)
      end

      it "updates message contents with rank name signature for a lower rank" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/usersay   Example text",
          entities: [
            Tourmaline::MessageEntity.new(
              "bot_command",
              0,
              8
            ),
            Tourmaline::MessageEntity.new(
              "bold",
              11,
              7
            ),
          ]
        )

        handler.do(message, services)

        unless updated_message = message
          fail("Message should not be nil")
        end

        expected_text = "Example text ~~User"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(1))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(13))
        updated_message.entities[0].length.should(eq(6))

        updated_message.preformatted?.should(be_true)
      end
    end

    describe "#spamming?" do
      it "returns true if user is spamming text" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay Example",
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

      it "returns false if no spam handler" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay Example",
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end

    describe "#get_rank_name" do
      # TODO: Check for names that include spaces
      updated_ranks = {
        1000 => Rank.new(
          "Host",
          Set{
            CommandPermissions::RanksayLower,
          },
          Set(MessagePermissions).new,
        ),
        100 => Rank.new(
          "Admin",
          Set{
            CommandPermissions::Ranksay,
          },
          Set(MessagePermissions).new,
        ),
        10 => Rank.new(
          "Mod",
          Set{
            CommandPermissions::Ranksay,
          },
          Set(MessagePermissions).new,
        ),
        0 => Rank.new(
          "User",
          Set(CommandPermissions).new,
          Set(MessagePermissions).new,
        ),
      }

      it "gets name of user's current rank" do
        services = create_services(ranks: updated_ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "user9000"),
        )

        text = "/ranksay   Example text"

        user = MockUser.new(9000, rank: 100)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::Ranksay,
          services,
        ).should(eq("Admin"))
      end

      it "gets name of rank contained in command" do
        services = create_services(ranks: updated_ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "user9000"),
        )

        text = "/modsay example text"

        user = MockUser.new(9000, rank: 1000)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::RanksayLower,
          services,
        ).should(eq("Mod"))
      end

      it "returns nil if given rank cannot ranksay" do
        services = create_services(ranks: updated_ranks, relay: MockRelay.new("", MockClient.new))

        handler = RanksayCommand.new(MockConfig.new)

        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "user9000"),
        )

        text = "/usersay example text"

        user = MockUser.new(9000, rank: 1000)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::RanksayLower,
          services,
        ).should(be_nil)
      end
    end
  end
end
