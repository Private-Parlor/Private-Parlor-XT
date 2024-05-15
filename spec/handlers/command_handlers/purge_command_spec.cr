require "../../spec_helper.cr"

module PrivateParlorXT
  describe PurgeCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Purge,
        },
        Set(MessagePermissions).new,
      ),
      0 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PurgeCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/purge",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "updates user activty" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PurgeCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/purge",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "deletes all message groups sent by the blacklisted user" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = PurgeCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        # Update blacklisted user
        unless user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        user.set_left
        services.database.update_user(user)

        services.history.new_message(70000, 11)
        services.history.new_message(70000, 15)

        services.history.add_to_history(11, 12, 20000)
        services.history.add_to_history(11, 13, 80300)
        services.history.add_to_history(11, 14, 60200)

        services.history.add_to_history(15, 16, 20000)
        services.history.add_to_history(15, 17, 80300)
        services.history.add_to_history(15, 18, 60200)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 50,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/purge",
          from: tourmaline_user,
        )

        handler.do(message, services)

        services.history.get_origin_message(12).should(be_nil)
        services.history.get_origin_message(13).should(be_nil)
        services.history.get_origin_message(14).should(be_nil)
        services.history.get_origin_message(15).should(be_nil)
        services.history.get_origin_message(16).should(be_nil)
        services.history.get_origin_message(17).should(be_nil)
        services.history.get_origin_message(18).should(be_nil)

        expected = Format.substitute_reply(services.replies.purge_complete, {
          "msgs_deleted" => "2",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end
  end
end
