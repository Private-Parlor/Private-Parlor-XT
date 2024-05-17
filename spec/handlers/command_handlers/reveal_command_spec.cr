require "../../spec_helper.cr"

module PrivateParlorXT
  describe RevealCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Reveal,
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
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if user has forward privacy enabled" do
        host_ranks = {
          1000 => Rank.new(
            "Host",
            Set{
              CommandPermissions::Reveal,
            },
            Set(MessagePermissions).new,
          ),
        }

        services = create_services(ranks: host_ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        reply = Tourmaline::Message.new(
          message_id: 9,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.private_sign))
      end

      it "returns early with 'no reply' if message has no reply" do
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.no_reply))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns early if user attempts to reveal username to himself" do
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 2,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "returns early is user is spamming signatures" do
        services = create_services(
          ranks: ranks,
          spam: SpamHandler.new,
        )

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        expected = handler.user_reveal(80300, "beispiel", services.replies)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        responses = [services.replies.success, expected]

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)

          responses = responses - [msg.data]
        end

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.sign_spam))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "reveals username to a user" do
        services = create_services(ranks: ranks)

        handler = RevealCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 10,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/reveal",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        expected = handler.user_reveal(80300, "beispiel", services.replies)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(2))

        responses = [services.replies.success, expected]

        messages.each do |msg|
          msg.data.in?(responses).should(be_true)

          responses = responses - [msg.data]
        end
      end
    end

    describe "#user_reveal" do
      it "returns Markdown link to the given user id" do
        services = create_services

        handler = RevealCommand.new(MockConfig.new)

        expected = "[user\\_name](tg://user?id=123456)"

        expected = Format.substitute_message(services.replies.username_reveal, {
          "username" => expected,
        })

        result = handler.user_reveal(123456, "user_name", services.replies)

        result.should(eq(expected))
      end
    end
  end
end
