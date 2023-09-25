require "../../spec_helper.cr"

module PrivateParlorXT

  describe TripcodeSignCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = TripcodeSignCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end
    
    describe "#do" do
      it "updates message contents" do
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

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        unless updated_message = ctx.message
          fail("Message should not be nil")
        end

        expected_text = "Voorb !JMf3r1v1Aw:\nExample text"

        updated_message.text.should(eq(expected_text))

        updated_message.entities.size.should(eq(3))

        updated_message.entities[0].type.should_not(eq("bot_command"))
        updated_message.entities[0].type.should(eq("bold"))
        updated_message.entities[0].offset.should(eq(0))
        updated_message.entities[0].length.should(eq(5))

        updated_message.entities[1].type.should(eq("code"))
        updated_message.entities[1].offset.should(eq(6))
        updated_message.entities[1].length.should(eq(11))

        updated_message.entities[2].type.should(eq("bold"))
        updated_message.entities[2].offset.should(eq(19))
        updated_message.entities[2].length.should(eq(7))
      end
    end

    describe "#is_spamming?" do
      it "returns true if user is sign spamming" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end
        
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        ctx = create_context(client, create_update(11, message))
        spam_services = create_services(client: client, spam: SpamHandler.new())

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.is_spamming?(beispiel, message, "", spam_services)

        unless expiration_time = spam.sign_last_used[beispiel.id]?
          fail("Expiration time should not be nil")
        end

        handler.is_spamming?(beispiel, message, "", spam_services).should(be_true)
      end

      it "returns true if user is spamming text" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end
        
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        ctx = create_context(client, create_update(11, message))
        spam_services = create_services(client: client, spam: SpamHandler.new(
          spam_limit: 10,
          score_character: 1,
          score_line: 0,
        ))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.is_spamming?(beispiel, message, "Example", spam_services)

        unless score = spam.scores[beispiel.id]?
          fail("Score should not be nil")
        end

        handler.is_spamming?(beispiel, message, "Example", spam_services).should(be_true)
      end

      it "returns false if user is not sign spamming" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spam_services = create_services(client: client, spam: SpamHandler.new())

        handler.is_spamming?(beispiel, message, "", spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        generate_users(services.database)

        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "/tsign Example",
        )

        spamless_services = create_services(client: client)

        handler.is_spamming?(beispiel, message, "", spamless_services).should(be_false)
      end
    end
  end
end