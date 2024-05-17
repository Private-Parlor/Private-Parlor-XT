require "../../spec_helper.cr"

module PrivateParlorXT
  describe TripcodeCommand do
    describe "#do" do
      it "returns early if tripcode is invalid" do
        services = create_services()

        handler = TripcodeCommand.new(MockConfig.new)
    
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/tripcode 🦤🦆🕊️#"
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.invalid_tripcode_format, {
          "valid_format" => services.replies.tripcode_format,
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns early if flag signature is invalid" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              flag_signatures: true
            ),
          ),
        )

        handler = TripcodeCommand.new(MockConfig.new)
    
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/tripcode name#password"
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.invalid_tripcode_format, {
          "valid_format" => services.replies.flag_sign_format,
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "updates user activity" do
        services = create_services()

        handler = TripcodeCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/tripcode",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)  
      end

      it "sets user tripcode" do
        services = create_services()

        handler = TripcodeCommand.new(MockConfig.new)
    
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/tripcode name#password"
        )

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.tripcode.should(eq("name#password"))

        name, code = Format.generate_tripcode("name#password", services)

        expected = handler.tripcode_set(
          services.replies.tripcode_set_format,
          name,
          code,
          services
        )

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "sets user flag signature" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(
              flag_signatures: true
            ),
          ),
        )

        handler = TripcodeCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        obfuscated_id = user.obfuscated_id

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/tripcode 🦤🦆🕊️"
        )

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.tripcode.should(eq("🦤🦆🕊️##{obfuscated_id}"))

        expected = handler.tripcode_set(
          services.replies.flag_sign_set_format,
          "🦤🦆🕊️",
          "",
          services
        )

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end

      it "returns user's current tripcode in command without arguments" do
        services = create_services()

        handler = TripcodeCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(20000, false, "example")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/tripcode"
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.tripcode_info, {
          "tripcode" => services.replies.tripcode_unset,
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))

        user.set_tripcode("name#example")
        
        services.database.update_user(user)

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.tripcode_info, {
          "tripcode" => user.tripcode,
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end

    describe "#valid_tripcode?" do
      it "returns false if arg does not contain a pound sign delimiter" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_tripcode?("example").should(be_false)
      end

      it "returns false if arg ends with a pound sign delimiter" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_tripcode?("example#").should(be_false)
        handler.valid_tripcode?("🦤🦆🕊️#").should(be_false)
      end

      it "returns false if arg contains a newline" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_tripcode?("example\n#pass").should(be_false)
        handler.valid_tripcode?("example#pass\n").should(be_false)
      end

      it "returns false if length of arg is more than 30 characters" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_tripcode?("example#AnExcessivelyLongTripcodePassword").should(be_false)
      end

      it "returns true if arg is formatted correctly" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_tripcode?("example#1").should(be_true)
        handler.valid_tripcode?("example#password").should(be_true)
        handler.valid_tripcode?("example#verboselongpassword123").should(be_true)
      end
    end

    describe "#valid_signature?" do
      it "returns false if signature is larger than 5 codepoints" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_signature?("🦤🦆🕊️🐦🦃").should(be_true)
        handler.valid_signature?("🦤🦆🕊️🐦🏴󠁧󠁢󠁳󠁣󠁴󠁿").should(be_true)
        handler.valid_signature?("🦤🦆🕊️🐦🦃🐓").should(be_false)
      end

      it "returns false if signature contains a newline" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_signature?("🦤🦆🕊️\n").should(be_false)
        handler.valid_signature?("🦤\n🦆🕊️").should(be_false)
      end

      it "returns false if signature contains invalid codepoints" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_signature?("do🦤🦆🕊️").should(be_false)
      end

      it "returns true if signature is valid" do
        handler = TripcodeCommand.new(MockConfig.new)

        handler.valid_signature?("🦤🦆🕊️").should(be_true)
        handler.valid_signature?("🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🇮🇲🇬🇧").should(be_true)
      end
    end

    describe "#tripcode_set" do
      it "returns tripcode set reponse" do
        services = create_services

        handler = TripcodeCommand.new(MockConfig.new)

        expected = Format.substitute_message(services.replies.tripcode_set, {
          "set_format" => Format.substitute_reply(services.replies.tripcode_set_format, {
            "name" => "name",
            "tripcode" => "!ozOtJW9BFA",
          })
        })

        result = handler.tripcode_set(
          services.replies.tripcode_set_format,
          "name",
          "!ozOtJW9BFA",
          services
        )

        result.should(eq(expected))

        expected = Format.substitute_message(services.replies.tripcode_set, {
          "set_format" => Format.substitute_reply(services.replies.flag_sign_set_format, {
            "name" => "🦤🦆🕊️🐦🦃",
          })
        })

        result = handler.tripcode_set(
          services.replies.flag_sign_set_format,
          "🦤🦆🕊️🐦🦃",
          "",
          services
        )

        result.should(eq(expected))
      end
    end
  end
end
