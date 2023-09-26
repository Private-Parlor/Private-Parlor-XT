require "../../spec_helper.cr"

module PrivateParlorXT
  describe MockCommandHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = MockCommandHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)

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

      it "returns message if user can't use a command (blacklisted)" do
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

      it "returns nil if message does not exist" do
        empty_context = create_context(client, create_update(11))

        tuple = handler.get_message_and_user(empty_context, services)

        tuple.should(eq({nil, nil}))
      end
    end

    describe "#authorized?" do
      it "returns true if user can use command" do
        user = services.database.get_user(80300)

        unless user
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.authorized?(user, message, :Ranksay, services).should(be_true)
      end

      it "returns false if use cannot use command" do
        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "beispiel"),
        )

        handler.authorized?(user, message, :Ranksay, services).should(be_false)
      end

      it "returns CommandPermission when given a group of permissions" do
        user = services.database.get_user(80300)

        unless user
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        authority = handler.authorized?(
          user,
          message,
          services,
          :Promote, :PromoteLower, :PromoteSame
        )

        authority.should(eq(CommandPermissions::PromoteSame))
      end

      it "returns nil if user does not have any of the given permissions" do
        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(60200, false, "voorbeeld"),
        )

        authority = handler.authorized?(
          user,
          message,
          services,
          :Promote, :PromoteLower, :PromoteSame
        )

        authority.should(be_nil)
      end
    end

    describe "#delete_messages" do
      it "deletes message group from history" do
        generate_history(services.history)

        handler.delete_messages(6, 20000, false, false, services)
        handler.delete_messages(9, 20000, false, true, services)

        services.history.get_origin_message(6).should(be_nil)
        services.history.get_origin_message(9).should(be_nil)
      end
    end
  end
end
