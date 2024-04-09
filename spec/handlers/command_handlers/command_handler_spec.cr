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

    describe "#get_user_from_message" do
      it "returns user" do
        reply_to = create_message(
          6,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          reply_to_message: reply_to,
        )

        unless returned_user = handler.get_user_from_message(message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
      end

      it "updates user's names" do
        new_names_message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel", "spec", "new_username"),
        )

        unless returned_user = handler.get_user_from_message(new_names_message, services)
          fail("Did not get a user from method")
        end

        returned_user.id.should(eq(80300))
        returned_user.username.should_not(be_nil)
        returned_user.username.should(be("new_username"))
        returned_user.realname.should(eq("beispiel spec"))
      end

      it "returns nil if user does not exist" do
        message = create_message(
          11,
          Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username"),
        )

        user = handler.get_user_from_message(message, services)

        user.should(be_nil)
      end

      it "queues not in chat message if user does not exist" do
        mock_services = create_services(relay: MockRelay.new("", client))

        message = create_message(
          11,
          Tourmaline::User.new(12345678, false, "beispiel", "spec", "new_username"),
        )

        handler.get_user_from_message(message, mock_services)

        messages = mock_services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(mock_services.replies.not_in_chat))
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

        handler.delete_messages(6, 20000, false, services)
        handler.delete_messages(9, 20000, false, services)

        services.history.get_origin_message(6).should(be_nil)
        services.history.get_origin_message(9).should(be_nil)
      end
    end
  end
end
