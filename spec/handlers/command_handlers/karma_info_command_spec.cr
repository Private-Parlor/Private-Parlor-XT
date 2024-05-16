require "../../spec_helper.cr"

module PrivateParlorXT
  describe KarmaInfoCommand do
    describe "#do" do
      it "returns early if there are no karma levels" do
        services = create_services(
          config: HandlerConfig.new(
            MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String)
          )
        )

        handler = KarmaInfoCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          caption: "/ksign Karma level sign",
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(0))
      end

      it "updates user activity" do
        services = create_services()

        handler = KarmaInfoCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/karma_info",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "returns message containing karma and karma level information" do
        services = create_services()

        handler = KarmaInfoCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/karma_info",
          from: tourmaline_user,
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.karma_info, {
          "current_level" => "Junk",
          "next_level"    => "Normal",
          "karma"         => "-20",
          "limit"         => "0",
          "loading_bar"   => Format.format_karma_loading_bar(100.0, services.locale),
          "percentage"    => "100.0",
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end
  end
end