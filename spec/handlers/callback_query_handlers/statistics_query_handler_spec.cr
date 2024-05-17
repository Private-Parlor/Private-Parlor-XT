require "../../spec_helper.cr"

module PrivateParlorXT
  describe StatisticsQueryHandler do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Users,
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
      it "returns early if callback has no message" do
        services = create_services(
          statistics: MockStatistics.new
        )

        generate_users(services.database)

        handler = StatisticsQueryHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          data: "statistics-next=General"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end

      it "returns early if callback has no data" do
        services = create_services(
          statistics: MockStatistics.new
        )

        generate_users(services.database)

        handler = StatisticsQueryHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end

      it "returns early if there is no Statistics object" do
        services = create_services()

        generate_users(services.database)

        handler = StatisticsQueryHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=General"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end

      it "returns early if there is no query string" do
        services = create_services(
          statistics: MockStatistics.new
        )

        generate_users(services.database)

        handler = StatisticsQueryHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end

      it "returns edited message text for given statistics screen" do
        services = create_services(
          ranks: ranks,
          statistics: MockStatistics.new
        )

        generate_users(services.database)

        unless stats = services.stats
          fail("Services should have a Statistics object")
        end

        handler = StatisticsQueryHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel", "newname", "@new_username")
        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        # Get General statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=General"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:General, services)))

        # Get Message statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=Messages"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:Messages, services)))

        # Get Full User statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=Users"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:Users, services)))

        # Get User statistics
        user_rank_user = Tourmaline::User.new(60200, false, "voorbeeld")
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: user_rank_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=Users"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.users_screen(services)))

        # Get Karma statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=Karma"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:Karma, services)))

        # Get Karma Level statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=KarmaLevels"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:KarmaLevels, services)))

        # Get Robot9000 statistics
        query = Tourmaline::CallbackQuery.new(
          id: "query_one",
          from: tourmaline_user,
          chat_instance: "",
          message: message,
          data: "statistics-next=Robot9000"
        )

        handler.do(query, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))
        
        messages[0].data.should(eq(stats.statistic_screen(:Robot9000, services)))
      end
    end
  end
end