require "../../spec_helper.cr"

module PrivateParlorXT
  describe RanksayCommand do
    client = MockClient.new

    ranks = {
      0 => Rank.new(
        "User",
        Set{
          CommandPermissions::Ranksay,
        },
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = RanksayCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        restricted_ranks = {
          0 => Rank.new(
            "User",
            Set(CommandPermissions).new,
            Set(MessagePermissions).new,
          ),
        }

        restricted_user_services = create_services(
          ranks: restricted_ranks,
          relay: MockRelay.new("", client),
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

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, restricted_user_services)

        messages = restricted_user_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(restricted_user_services.replies.command_disabled))
      end

      it "updates message contents" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld", username: "voorb"),
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

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        unless updated_message = ctx.message
          fail("Message should not be nil")
        end

        expected_text = "Example text ~~User"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(2))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(0))
        updated_message.entities[0].length.should(eq(7))

        updated_message.entities[1].type.should(eq("bold"))
        updated_message.entities[1].offset.should(eq(13))
        updated_message.entities[1].length.should(eq(6))
      end
    end

    describe "#spamming?" do
      it "returns true if user is spamming text" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/ranksay Example",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new(
          spam_limit: 10,
          score_character: 1,
          score_line: 0,
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
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/sign Example",
        )

        spamless_services = create_services(client: client)

        handler.spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end

    describe "#get_rank_name" do
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
        ranks_services = create_services(ranks: updated_ranks, relay: MockRelay.new("", client))

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
        )

        text = "/ranksay   Example text"

        user = MockUser.new(9000, rank: 100)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::Ranksay,
          ranks_services,
        ).should(eq("Admin"))
      end

      it "gets name of rank contained in command" do
        ranks_services = create_services(ranks: updated_ranks, relay: MockRelay.new("", client))

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
        )

        text = "/modsay example text"

        user = MockUser.new(9000, rank: 1000)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::RanksayLower,
          ranks_services,
        ).should(eq("Mod"))
      end

      it "returns nil if given rank cannot ranksay" do
        ranks_services = create_services(ranks: updated_ranks, relay: MockRelay.new("", client))

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
        )

        text = "/usersay example text"

        user = MockUser.new(9000, rank: 1000)

        handler.get_rank_name(
          text,
          user,
          message,
          CommandPermissions::RanksayLower,
          ranks_services,
        ).should(be_nil)
      end
    end
  end
end
