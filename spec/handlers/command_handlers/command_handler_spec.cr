require "../../spec_helper.cr"

module PrivateParlorXT
  describe CommandHandler do
    describe "#get_user_from_message" do
      it "returns user" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

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
          from: tourmaline_user,
          reply_to_message: reply,
        )

        unless returned_user = handler.get_user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username")

        new_names_message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        unless returned_user = handler.get_user_from_message(new_names_message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns nil if message has no sender" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        handler.get_user_from_message(message, services).should(be_nil)
      end

      it "returns nil if message does not contain a command" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "Example text"
        )

        handler.get_user_from_message(message, services).should(be_nil)
      end

      it "returns nil if user does not exist and queues 'not_in_chat' reply" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)
        
        tourmaline_user = Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.get_user_from_message(message, services).should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "returns nil if user is blacklisted" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(70000, false, "esimerkki")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user
        )

        handler.get_user_from_message(message, services).should(be_nil)
      end
    end

    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

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
    end

    describe "#authorized?" do
      it "returns true if user can use command" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(80300)

        unless user
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.authorized?(user, message, :Ranksay, services).should(be_true)
      end

      it "returns false if use cannot use command" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(60200, false, "voorbeeld")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        handler.authorized?(user, message, :Ranksay, services).should(be_false)
      end

      it "returns CommandPermission when given a group of permissions" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(80300)

        unless user
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        authority = handler.authorized?(
          user,
          message,
          services,
          :Promote, :PromoteLower, :PromoteSame
        )

        authority.should(eq(CommandPermissions::PromoteSame))
      end

      it "returns nil and queues command disabled response if user does not have any of the given permissions" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_users(services.database)

        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(60200, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
        )

        authority = handler.authorized?(
          user,
          message,
          services,
          :Promote, :PromoteLower, :PromoteSame
        )

        authority.should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.command_disabled))
      end
    end

    describe "#delete_messages" do
      it "deletes message group from history" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        generate_history(services.history)

        handler.delete_messages(6, 20000, false, services).should(eq(4))
        handler.delete_messages(9, 20000, false, services).should(eq(8))

        services.history.get_origin_message(6).should(be_nil)
        services.history.get_origin_message(9).should(be_nil)
      end
    end

    describe "#update_entities" do
      it "returns entities without bot command and other entities' offsets modified" do
        services = create_services()
        handler = MockCommandHandler.new(MockConfig.new)

        entities = [
          Tourmaline::MessageEntity.new(
            type: "bot_command",
            offset: 0,
            length: 8,
          ),
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 9,
            length: 4,
          ),
          Tourmaline::MessageEntity.new(
            type: "underline",
            offset: 13,
            length: 13,
          ),
          Tourmaline::MessageEntity.new(
            type: "text_link",
            offset: 9,
            length: 25,
            url: "www.google.com"
          ),
        ]

        result = handler.update_entities(
          "/example Text with entities and backlinks >>>/foo/", 
          entities, 
          "Text with entities and backlinks >>>/foo/"
        )

        result.size.should(eq(3))

        result[0].type.should(eq("bold"))
        result[0].offset.should(eq(0))
        result[0].length.should(eq(4))

        result[1].type.should(eq("underline"))
        result[1].offset.should(eq(4))
        result[1].length.should(eq(13))

        result[2].type.should(eq("text_link"))
        result[2].offset.should(eq(0))
        result[2].length.should(eq(25))
      end
    end
  end
end
