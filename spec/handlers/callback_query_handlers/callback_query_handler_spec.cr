require "../../spec_helper.cr"

module PrivateParlorXT
  class MockCallbackHandler < CallbackHandler
    def do(callback : Tourmaline::CallbackQuery, services : Services) : Nil
    end
  end

  describe CallbackHandler do
    describe "#get_user_from_callback" do 
      it "returns user with updated names" do
        services = create_services()
        handler = MockCallbackHandler.new(MockConfig.new)

        generate_users(services.database)
        
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
        )

        unless user = handler.get_user_from_callback(query, services)
          fail("Did not get a user from method")
        end

        user.id.should(eq(80300))
        user.realname.should(eq("beispiel newname"))
        user.username.should(eq("@new_username"))
      end

      it "returns nil if user does not exist and queues 'not_in_chat' reply" do
        services = create_services(relay: MockRelay.new("", MockClient.new))
        handler = MockCallbackHandler.new(MockConfig.new)

        generate_users(services.database)
        
        tourmaline_user = Tourmaline::User.new(9000, false, "not_in_chat")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
        )

        handler.get_user_from_callback(query, services).should(be_nil)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_chat))
      end

      it "returns nil if user is blacklisted" do
        services = create_services()
        handler = MockCallbackHandler.new(MockConfig.new)

        generate_users(services.database)
        
        tourmaline_user = Tourmaline::User.new(70000, false, "BLACKLISTED")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
        )

        handler.get_user_from_callback(query, services).should(be_nil)
      end
    end

    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        services = create_services(relay: MockRelay.new("", MockClient.new))
        handler = MockCallbackHandler.new(MockConfig.new)

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
  end
end