require "../../spec_helper.cr"

module PrivateParlorXT
  describe StatsCommand do
    describe "#do" do
      it "returns early if statistics are not enabled" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = StatsCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/stats",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)
        
        services = create_services(
          database: database,
          statistics: SQLiteStatistics.new(connection),
          relay: MockRelay.new("", MockClient.new)
        )

        handler = StatsCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/stats",
          from: tourmaline_user
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "returns message containing general bot statistics" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)
        
        services = create_services(
          database: database,
          statistics: SQLiteStatistics.new(connection),
          relay: MockRelay.new("", MockClient.new)
        )

        start_time = Time.utc

        handler = StatsCommand.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 11,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/stats",
          from: tourmaline_user
        )

        handler.do(message, services)

        uptime = Time.utc - start_time

        expected = Format.substitute_reply(services.replies.config_stats, {
          "start_date"           => Time.utc.to_s("%Y-%m-%d"),
          "days" => uptime.days.to_s,
          "hours" => uptime.hours.to_s,
          "minutes" => uptime.minutes.to_s,
          "seconds" => uptime.seconds.to_s,
          "registration_toggle"  => services.locale.toggle[1],
          "media_limit_period"   => Format.format_time_span(Time::Span.new(hours: 120), services.locale),
          "message_lifespan"     => services.locale.toggle[0],
          "pseudonymous_toggle"  => services.locale.toggle[0],
          "spoilers_toggle"      => services.locale.toggle[0],
          "karma_reasons_toggle" => services.locale.toggle[0],
          "robot9000_toggle"     => services.locale.toggle[0],
          "karma_economy_toggle" => services.locale.toggle[0],
        })

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        result = messages[0].data

        # Replace uptime data with something we know
        result = result.gsub(/Current uptime: .+ seconds/,
          Format.substitute_reply("Current uptime: {days} days, {hours} hours, {minutes} minutes, {seconds} seconds",
          {
            "days" => uptime.days.to_s,
            "hours" => uptime.hours.to_s,
            "minutes" => uptime.minutes.to_s,
            "seconds" => uptime.seconds.to_s,
          })
        )

        result.should(eq(expected))
      end
    end
  end
end