require "../../spec_helper.cr"

module PrivateParlorXT
  describe InfoCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::RankedInfo,
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
      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

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
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "returns info about the invoker" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

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
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        obfuscated_karma = reply_user.obfuscated_karma.to_s

        expected = Format.substitute_reply(services.replies.ranked_info, {
          "oid"            => reply_user.obfuscated_id.to_s,
          "karma"          => obfuscated_karma,
          "cooldown_until" => handler.cooldown_until(reply_user.cooldown_until, services),
        })

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        result = messages[0].data

        # Replace obfuscated karma with something we know
        result = result.gsub(/.+karma.+:.*/, "*karma*: {karma}")

        result = Format.substitute_reply(result, {"karma" => obfuscated_karma})

        result.should(eq(expected))
      end

      it "returns info about the given user" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/info",
          from: tourmaline_user,
        )

        expected = Format.substitute_reply(services.replies.user_info, {
          "oid"            => user.obfuscated_id.to_s,
          "username"       => "beispiel",
          "rank_val"       => "10",
          "rank"           => "Mod",
          "karma"          => "-20",
          "karma_level"    => "(Junk)",
          "warnings"       => "2",
          "warn_expiry"    => handler.warn_expiry(user.warn_expiry, services),
          "smiley"         => ":|",
          "cooldown_until" => handler.cooldown_until(user.cooldown_until, services),
        })

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end

    describe "#ranked_info" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

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
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.ranked_info(user, message, reply, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do 
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

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
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.ranked_info(user, message, reply, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "removes cooldown from reply user if it has expired" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        services.history.new_message(50000_i64, 11)
        services.history.add_to_history(11, 12, 80300)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 12,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        message = Tourmaline::Message.new(
          message_id: 13,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        handler.ranked_info(user, message, reply, services)

        unless uncooldowned_user = services.database.get_user(50000)
          fail("User 50000 should exist in the database")
        end

        user.cooldown_until.should(be_nil)
      end

      it "returns info about the reply user" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

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
          text: "/info",
          from: tourmaline_user,
          reply_to_message: reply
        )

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        obfuscated_karma = reply_user.obfuscated_karma.to_s

        expected = Format.substitute_reply(services.replies.ranked_info, {
          "oid"            => reply_user.obfuscated_id.to_s,
          "karma"          => obfuscated_karma,
          "cooldown_until" => handler.cooldown_until(reply_user.cooldown_until, services),
        })

        unless result = handler.ranked_info(user, message, reply, services)
          fail("Method should have returned a response")
        end

        # Replace obfuscated karma with something we know
        result = result.gsub(/.+karma.+:.*/, "*karma*: {karma}")

        result = Format.substitute_reply(result, {"karma" => obfuscated_karma})

        result.should(eq(expected))
      end
    end

    describe "#user_info" do
      it "returns info about the invoker" do
        services = create_services(ranks: ranks)

        handler = InfoCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/info",
          from: tourmaline_user,
        )

        expected = Format.substitute_reply(services.replies.user_info, {
          "oid"            => user.obfuscated_id.to_s,
          "username"       => "beispiel",
          "rank_val"       => "10",
          "rank"           => "Mod",
          "karma"          => "-20",
          "karma_level"    => "(Junk)",
          "warnings"       => "2",
          "warn_expiry"    => handler.warn_expiry(user.warn_expiry, services),
          "smiley"         => ":|",
          "cooldown_until" => handler.cooldown_until(user.cooldown_until, services),
        })

        unless result = handler.user_info(user, services)
          fail("Method should have returned a response")
        end

        result.should(eq(expected))
      end
    end

    describe "#cooldown_until" do
      it "returns cooldown time response" do
        services = create_services

        handler = InfoCommand.new(MockConfig.new)

        time = Time.utc

        expected = "#{services.replies.cooldown_true} #{Format.time(time, services.locale.time_format)}"

        result = handler.cooldown_until(time, services)

        result.should(eq(expected))
      end

      it "returns a no cooldown response if time is nil" do
        services = create_services

        handler = InfoCommand.new(MockConfig.new)

        result = handler.cooldown_until(nil, services)

        result.should(eq(services.replies.cooldown_false))
      end
    end

    describe "#warn_expiry" do
      it "returns warning expiration response" do
        services = create_services

        handler = InfoCommand.new(MockConfig.new)

        time = Time.utc

        expected = Format.substitute_message(services.replies.info_warning, {
          "warn_expiry" => Format.time(time, services.locale.time_format)
        })

        result = handler.warn_expiry(time, services)

        result.should(eq(expected))
      end

      it "returns nil if expiration time is nil" do
        services = create_services

        handler = InfoCommand.new(MockConfig.new)

        result = handler.warn_expiry(nil, services)

        result.should(be_nil)
      end
    end

    describe "#smiley" do
      it "returns smiley face based on number of given warnings" do
        handler = InfoCommand.new(
          MockConfig.new(
            smileys: [":)", ":O", ":/", ">:("]
          )
        )

        handler.smiley(0).should(eq(":)"))
        handler.smiley(1).should(eq(":O"))
        handler.smiley(2).should(eq(":O"))
        handler.smiley(3).should(eq(":/"))
        handler.smiley(4).should(eq(":/"))
        handler.smiley(5).should(eq(":/"))
        handler.smiley(6).should(eq(">:("))
        handler.smiley(7).should(eq(">:("))
      end
    end
  end
end