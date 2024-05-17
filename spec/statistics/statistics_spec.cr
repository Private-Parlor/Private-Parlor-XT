require "../spec_helper.cr"

module PrivateParlorXT
  describe Statistics do
    describe "#uptime" do
      it "returns time span since class instantiation" do
        stats = MockStatistics.new

        uptime = stats.uptime

        uptime.should(be_a(Time::Span))
        uptime.should(be > Time::Span.new)
      end
    end

    describe "#configuration_details" do
      it "returns hash of bot details based on services object" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(
          MockConfig.new(
            media_limit_period: 24,
            registration_open: false,
            pseudonymous: true,
            media_spoilers: true,
            karma_reasons: false,
          )
        )
        history = CachedHistory.new(14.hours)
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, history: history, r9k: r9k)

        stats = MockStatistics.new

        hash = stats.configuration_details(services)

        hash[Statistics::BotInfo::RegistrationToggle].should(eq(services.locale.toggle[0]))
        hash[Statistics::BotInfo::MediaLimitPeriod].should(eq(Format.time_span(Time::Span.new(hours: 24), services.locale)))
        hash[Statistics::BotInfo::MessageLifespan].should(eq(Format.time_span(Time::Span.new(hours: 14), services.locale)))
        hash[Statistics::BotInfo::PseudonymousToggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::SpoilerToggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::KarmaReasonsToggle].should(eq(services.locale.toggle[0]))
        hash[Statistics::BotInfo::Robot9000Toggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::KarmaEconomyToggle].should(eq(services.locale.toggle[0]))
      end
    end

    describe "#statistic_screen" do
      it "returns formatted general info screen" do
        start_time = Time.utc

        config = HandlerConfig.new(
          MockConfig.new(
            media_limit_period: 38,
            registration_open: true,
            pseudonymous: false,
            media_spoilers: true,
            karma_reasons: true,
          )
        )
        karma_economy = KarmaHandler.new

        services = create_services(config: config, karma_economy: karma_economy)

        stats = MockStatistics.new

        result = stats.statistic_screen(:General, services)

        uptime = Time.utc - start_time

        # Replace uptime data with something we know
        result = result.gsub(/Current uptime: .+ seconds/,
          Format.substitute_reply("Current uptime: {days} days, {hours} hours, {minutes} minutes, {seconds} seconds",
            {
              "days"    => uptime.days.to_s,
              "hours"   => uptime.hours.to_s,
              "minutes" => uptime.minutes.to_s,
              "seconds" => uptime.seconds.to_s,
            })
        )

        expected = Format.substitute_reply(services.replies.config_stats, {
          "start_date"           => "MOCKED!",
          "days"                 => uptime.days.to_s,
          "hours"                => uptime.hours.to_s,
          "minutes"              => uptime.minutes.to_s,
          "seconds"              => uptime.seconds.to_s,
          "registration_toggle"  => services.locale.toggle[1],
          "media_limit_period"   => Format.time_span(Time::Span.new(hours: 38), services.locale),
          "message_lifespan"     => services.locale.toggle[0],
          "pseudonymous_toggle"  => services.locale.toggle[0],
          "spoilers_toggle"      => services.locale.toggle[1],
          "karma_reasons_toggle" => services.locale.toggle[1],
          "robot9000_toggle"     => services.locale.toggle[0],
          "karma_economy_toggle" => services.locale.toggle[1],
        })

        result.should(eq(expected))
      end

      it "returns formatted message stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.statistic_screen(:Messages, services)

        expected = Format.substitute_reply(services.replies.message_stats, {
          "total"             => "38",
          "album_total"       => "2",
          "animation_total"   => "5",
          "audio_total"       => "7",
          "contact_total"     => "0",
          "document_total"    => "2",
          "forward_total"     => "3",
          "location_total"    => "0",
          "photo_total"       => "0",
          "poll_total"        => "1",
          "sticker_total"     => "0",
          "text_total"        => "10",
          "venue_total"       => "0",
          "video_total"       => "5",
          "video_note_total"  => "0",
          "voice_total"       => "3",
          "daily_total"       => "8",
          "weekly_total"      => "16",
          "monthly_total"     => "28",
          "daily_change"      => "100.0",
          "weekly_change"     => "33.3",
          "monthly_change"    => "180.0",
          "change_today"      => services.locale.change[1],
          "change_this_week"  => services.locale.change[1],
          "change_this_month" => services.locale.change[1],
        })

        result.should(eq(expected))
      end

      it "returns formatted user stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.statistic_screen(:Users, services)

        expected = Format.substitute_reply(services.replies.full_user_stats, {
          "total_users"              => "30",
          "joined_users"             => "19",
          "left_users"               => "11",
          "blacklisted_users"        => "4",
          "joined_daily_total"       => "4",
          "joined_weekly_total"      => "17",
          "joined_monthly_total"     => "25",
          "joined_daily_change"      => "-20.0",
          "joined_weekly_change"     => "240.0",
          "joined_monthly_change"    => "400.0",
          "joined_change_today"      => services.locale.change[0],
          "joined_change_this_week"  => services.locale.change[1],
          "joined_change_this_month" => services.locale.change[1],
          "left_daily_total"         => "2",
          "left_weekly_total"        => "4",
          "left_monthly_total"       => "10",
          "left_daily_change"        => "100.0",
          "left_weekly_change"       => "-20.0",
          "left_monthly_change"      => "900.0",
          "left_change_today"        => services.locale.change[1],
          "left_change_this_week"    => services.locale.change[0],
          "left_change_this_month"   => services.locale.change[1],
          "net_daily"                => "2",
          "net_weekly"               => "13",
          "net_monthly"              => "15",
        })

        result.should(eq(expected))
      end

      it "returns formatted karma stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.statistic_screen(:Karma, services)

        expected = Format.substitute_reply(services.replies.karma_stats, {
          "upvotes"                    => "45",
          "downvotes"                  => "27",
          "upvote_daily_total"         => "10",
          "upvote_weekly_total"        => "14",
          "upvote_monthly_total"       => "32",
          "upvote_daily_change"        => "233.3",
          "upvote_weekly_change"       => "-17.6",
          "upvote_monthly_change"      => "146.2",
          "upvote_change_today"        => services.locale.change[1],
          "upvote_change_this_week"    => services.locale.change[0],
          "upvote_change_this_month"   => services.locale.change[1],
          "downvote_daily_total"       => "2",
          "downvote_weekly_total"      => "8",
          "downvote_monthly_total"     => "18",
          "downvote_daily_change"      => "-50.0",
          "downvote_weekly_change"     => "-20.0",
          "downvote_monthly_change"    => "100.0",
          "downvote_change_today"      => services.locale.change[0],
          "downvote_change_this_week"  => services.locale.change[0],
          "downvote_change_this_month" => services.locale.change[1],
        })

        result.should(eq(expected))
      end

      it "returns formatted karma level counts screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.statistic_screen(:KarmaLevels, services)

        karma_level_counts = \
           "Junk: 3\n" \
         "Normal: 2\n" \
         "Common: 3\n" \
         "Uncommon: 1\n" \
         "Rare: 1\n" \
         "Legendary: 1\n" \
         "Unique: 1\n"

        expected = Format.substitute_reply(services.replies.karma_level_stats, {
          "karma_levels" => karma_level_counts,
        })

        result.should(eq(expected))
      end

      it "returns formatted robot9000 stats screen" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(MockConfig.new)
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new

        result = stats.statistic_screen(:Robot9000, services)

        expected = Format.substitute_reply(services.replies.robot9000_stats, {
          "total_unique"     => "46",
          "unique_text"      => "27",
          "unique_media"     => "19",
          "total_unoriginal" => "12",
          "unoriginal_text"  => "7",
          "unoriginal_media" => "5",
        })

        result.should(eq(expected))
      end
    end

    describe "#percent_change" do
      it "returns the percent change from initial to final value" do
        stats = MockStatistics.new

        stats.percent_change(1, 4).should(eq(300.0))
        stats.percent_change(50, 25).should(eq(-50.0))
        stats.percent_change(567, 423).should(be_close(-25.4, 0.05))
        stats.percent_change(23, 697).should(be_close(2930.4, 0.05))
      end
    end

    describe "#keyboard_markup" do
      it "returns keyboard markup with 3 buttons in rows of three" do
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String))

        services = create_services(config: config)

        stats = MockStatistics.new

        keyboard = stats.keyboard_markup(:Users, services)

        keyboard.should(be_a(Tourmaline::InlineKeyboardMarkup))

        keyboard.inline_keyboard.size.should(eq(1))
        keyboard.inline_keyboard[0].size.should(eq(3))

        available_callbacks = [
          "statistics-next=#{Statistics::StatScreens::General}",
          "statistics-next=#{Statistics::StatScreens::Messages}",
          "statistics-next=#{Statistics::StatScreens::Karma}",
        ]

        keyboard.inline_keyboard[0].each do |button|
          available_callbacks.should(contain(button.callback_data))

          available_callbacks = available_callbacks - [button.callback_data]
        end
      end

      it "returns keyboard markup with 4 buttons in rows of three with karma levels or r9k" do
        config = HandlerConfig.new(MockConfig.new)
        services = create_services(config: config)

        stats = MockStatistics.new

        keyboard = stats.keyboard_markup(:Karma, services)

        keyboard.inline_keyboard.size.should(eq(2))
        keyboard.inline_keyboard[0].size.should(eq(3))
        keyboard.inline_keyboard[1].size.should(eq(1))

        buttons = keyboard.inline_keyboard[0] + keyboard.inline_keyboard[1]

        available_callbacks = [
          "statistics-next=#{Statistics::StatScreens::General}",
          "statistics-next=#{Statistics::StatScreens::Messages}",
          "statistics-next=#{Statistics::StatScreens::Users}",
          "statistics-next=#{Statistics::StatScreens::KarmaLevels}",
        ]

        buttons.each do |button|
          available_callbacks.should(contain(button.callback_data))

          available_callbacks = available_callbacks - [button.callback_data]
        end

        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String))
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        keyboard = stats.keyboard_markup(:General, services)

        keyboard.inline_keyboard.size.should(eq(2))
        keyboard.inline_keyboard[0].size.should(eq(3))
        keyboard.inline_keyboard[1].size.should(eq(1))

        buttons = keyboard.inline_keyboard[0] + keyboard.inline_keyboard[1]

        available_callbacks = [
          "statistics-next=#{Statistics::StatScreens::Messages}",
          "statistics-next=#{Statistics::StatScreens::Users}",
          "statistics-next=#{Statistics::StatScreens::Karma}",
          "statistics-next=#{Statistics::StatScreens::Robot9000}",
        ]

        buttons.each do |button|
          available_callbacks.should(contain(button.callback_data))

          available_callbacks = available_callbacks - [button.callback_data]
        end
      end

      it "returns keyboard markup with 5 buttons in rows of three with karma levels and r9k" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(MockConfig.new)
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new

        keyboard = stats.keyboard_markup(:Robot9000, services)

        keyboard.inline_keyboard.size.should(eq(2))
        keyboard.inline_keyboard[0].size.should(eq(3))
        keyboard.inline_keyboard[1].size.should(eq(2))

        buttons = keyboard.inline_keyboard[0] + keyboard.inline_keyboard[1]

        available_callbacks = [
          "statistics-next=#{Statistics::StatScreens::General}",
          "statistics-next=#{Statistics::StatScreens::Messages}",
          "statistics-next=#{Statistics::StatScreens::Users}",
          "statistics-next=#{Statistics::StatScreens::Karma}",
          "statistics-next=#{Statistics::StatScreens::KarmaLevels}",
        ]

        buttons.each do |button|
          available_callbacks.should(contain(button.callback_data))

          available_callbacks = available_callbacks - [button.callback_data]
        end
      end
    end

    describe "#config_screen" do
      it "returns formatted bot info screen" do
        start_time = Time.utc

        config = HandlerConfig.new(
          MockConfig.new(
            media_limit_period: 38,
            registration_open: true,
            pseudonymous: false,
            media_spoilers: true,
            karma_reasons: true,
          )
        )
        karma_economy = KarmaHandler.new

        services = create_services(config: config, karma_economy: karma_economy)

        stats = MockStatistics.new

        result = stats.config_screen(services)

        uptime = Time.utc - start_time

        # Replace uptime data with something we know
        result = result.gsub(/Current uptime: .+ seconds/,
          Format.substitute_reply("Current uptime: {days} days, {hours} hours, {minutes} minutes, {seconds} seconds",
            {
              "days"    => uptime.days.to_s,
              "hours"   => uptime.hours.to_s,
              "minutes" => uptime.minutes.to_s,
              "seconds" => uptime.seconds.to_s,
            })
        )

        expected = Format.substitute_reply(services.replies.config_stats, {
          "start_date"           => "MOCKED!",
          "days"                 => uptime.days.to_s,
          "hours"                => uptime.hours.to_s,
          "minutes"              => uptime.minutes.to_s,
          "seconds"              => uptime.seconds.to_s,
          "registration_toggle"  => services.locale.toggle[1],
          "media_limit_period"   => Format.time_span(Time::Span.new(hours: 38), services.locale),
          "message_lifespan"     => services.locale.toggle[0],
          "pseudonymous_toggle"  => services.locale.toggle[0],
          "spoilers_toggle"      => services.locale.toggle[1],
          "karma_reasons_toggle" => services.locale.toggle[1],
          "robot9000_toggle"     => services.locale.toggle[0],
          "karma_economy_toggle" => services.locale.toggle[1],
        })

        result.should(eq(expected))
      end
    end

    describe "#message_screen" do
      it "returns formatted message stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.messages_screen(services)

        expected = Format.substitute_reply(services.replies.message_stats, {
          "total"             => "38",
          "album_total"       => "2",
          "animation_total"   => "5",
          "audio_total"       => "7",
          "contact_total"     => "0",
          "document_total"    => "2",
          "forward_total"     => "3",
          "location_total"    => "0",
          "photo_total"       => "0",
          "poll_total"        => "1",
          "sticker_total"     => "0",
          "text_total"        => "10",
          "venue_total"       => "0",
          "video_total"       => "5",
          "video_note_total"  => "0",
          "voice_total"       => "3",
          "daily_total"       => "8",
          "weekly_total"      => "16",
          "monthly_total"     => "28",
          "daily_change"      => "100.0",
          "weekly_change"     => "33.3",
          "monthly_change"    => "180.0",
          "change_today"      => services.locale.change[1],
          "change_this_week"  => services.locale.change[1],
          "change_this_month" => services.locale.change[1],
        })

        result.should(eq(expected))
      end
    end

    describe "#full_users_screen" do
      it "returns formatted full user stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.full_users_screen(services)

        expected = Format.substitute_reply(services.replies.full_user_stats, {
          "total_users"              => "30",
          "joined_users"             => "19",
          "left_users"               => "11",
          "blacklisted_users"        => "4",
          "joined_daily_total"       => "4",
          "joined_weekly_total"      => "17",
          "joined_monthly_total"     => "25",
          "joined_daily_change"      => "-20.0",
          "joined_weekly_change"     => "240.0",
          "joined_monthly_change"    => "400.0",
          "joined_change_today"      => services.locale.change[0],
          "joined_change_this_week"  => services.locale.change[1],
          "joined_change_this_month" => services.locale.change[1],
          "left_daily_total"         => "2",
          "left_weekly_total"        => "4",
          "left_monthly_total"       => "10",
          "left_daily_change"        => "100.0",
          "left_weekly_change"       => "-20.0",
          "left_monthly_change"      => "900.0",
          "left_change_today"        => services.locale.change[1],
          "left_change_this_week"    => services.locale.change[0],
          "left_change_this_month"   => services.locale.change[1],
          "net_daily"                => "2",
          "net_weekly"               => "13",
          "net_monthly"              => "15",
        })

        result.should(eq(expected))
      end
    end

    describe "#users_screen" do
      it "returns formatted user stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.users_screen(services)

        expected = Format.substitute_reply(services.replies.user_stats, {
          "total_users" => "30",
          "net_daily"   => "2",
          "net_weekly"  => "13",
          "net_monthly" => "15",
        })

        result.should(eq(expected))
      end
    end

    describe "#karma_screen" do
      it "returns formatted karma stats screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.karma_screen(services)

        expected = Format.substitute_reply(services.replies.karma_stats, {
          "upvotes"                    => "45",
          "downvotes"                  => "27",
          "upvote_daily_total"         => "10",
          "upvote_weekly_total"        => "14",
          "upvote_monthly_total"       => "32",
          "upvote_daily_change"        => "233.3",
          "upvote_weekly_change"       => "-17.6",
          "upvote_monthly_change"      => "146.2",
          "upvote_change_today"        => services.locale.change[1],
          "upvote_change_this_week"    => services.locale.change[0],
          "upvote_change_this_month"   => services.locale.change[1],
          "downvote_daily_total"       => "2",
          "downvote_weekly_total"      => "8",
          "downvote_monthly_total"     => "18",
          "downvote_daily_change"      => "-50.0",
          "downvote_weekly_change"     => "-20.0",
          "downvote_monthly_change"    => "100.0",
          "downvote_change_today"      => services.locale.change[0],
          "downvote_change_this_week"  => services.locale.change[0],
          "downvote_change_this_month" => services.locale.change[1],
        })

        result.should(eq(expected))
      end
    end

    describe "#karma_levels_screen" do
      it "returns formatted karma level counts screen" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.karma_levels_screen(services)

        karma_level_counts = \
           "Junk: 3\n" \
         "Normal: 2\n" \
         "Common: 3\n" \
         "Uncommon: 1\n" \
         "Rare: 1\n" \
         "Legendary: 1\n" \
         "Unique: 1\n"

        expected = Format.substitute_reply(services.replies.karma_level_stats, {
          "karma_levels" => karma_level_counts,
        })

        result.should(eq(expected))
      end

      it "return no stats available message when karma levels are empty" do
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Range(Int32, Int32) => String))

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.karma_levels_screen(services)

        result.should(eq(services.replies.no_stats_available))
      end
    end

    describe "#robot9000_screen" do
      it "returns formatted robot9000 stats screen" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(MockConfig.new)
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new

        result = stats.robot9000_screen(services)

        expected = Format.substitute_reply(services.replies.robot9000_stats, {
          "total_unique"     => "46",
          "unique_text"      => "27",
          "unique_media"     => "19",
          "total_unoriginal" => "12",
          "unoriginal_text"  => "7",
          "unoriginal_media" => "5",
        })

        result.should(eq(expected))
      end

      it "return no stats available message when r9k is not toggled" do
        config = HandlerConfig.new(MockConfig.new)

        services = create_services(config: config)

        stats = MockStatistics.new

        result = stats.robot9000_screen(services)

        result.should(eq(services.replies.no_stats_available))
      end
    end
  end
end
