require "../spec_helper.cr"

module PrivateParlorXT
  class MockStatistics < Statistics
    def get_start_date : String
      "MOCKED!"
    end

    def increment_message_count(type : MessageCounts) : Nil
    end

    def increment_upvote_count : Nil
    end

    def increment_downvote_count : Nil
    end

    def increment_unoriginal_text_count : Nil
    end

    def increment_unoriginal_media_count : Nil
    end

    def get_total_messages : Hash(MessageCounts, Int32)
      {
        Statistics::MessageCounts::TotalMessages => 38,
        Statistics::MessageCounts::Albums => 2,
        Statistics::MessageCounts::Animations => 5,
        Statistics::MessageCounts::Audio => 7,
        Statistics::MessageCounts::Contacts => 0,
        Statistics::MessageCounts::Documents => 2,
        Statistics::MessageCounts::Forwards => 3,
        Statistics::MessageCounts::Locations => 0,
        Statistics::MessageCounts::Photos => 0,
        Statistics::MessageCounts::Polls => 1,
        Statistics::MessageCounts::Stickers => 0,
        Statistics::MessageCounts::Text => 10,
        Statistics::MessageCounts::Venues => 0,
        Statistics::MessageCounts::Videos => 5,
        Statistics::MessageCounts::VideoNotes => 0,
        Statistics::MessageCounts::Voice => 3,
        Statistics::MessageCounts::MessagesDaily => 8,
        Statistics::MessageCounts::MessagesYesterday => 4,
        Statistics::MessageCounts::MessagesWeekly => 16,
        Statistics::MessageCounts::MessagesYesterweek => 12,
        Statistics::MessageCounts::MessagesMonthly => 28,
        Statistics::MessageCounts::MessagesYestermonth => 10,
      }
    end

    def get_user_counts : Hash(UserCounts, Int32)
      {
        Statistics::UserCounts::TotalUsers => 30, 
        Statistics::UserCounts::TotalJoined => 19, 
        Statistics::UserCounts::TotalLeft => 11, 
        Statistics::UserCounts::TotalBlacklisted => 4, 
        Statistics::UserCounts::JoinedDaily => 4, 
        Statistics::UserCounts::JoinedYesterday => 5, 
        Statistics::UserCounts::JoinedWeekly => 17, 
        Statistics::UserCounts::JoinedYesterweek => 5, 
        Statistics::UserCounts::JoinedMonthly => 25, 
        Statistics::UserCounts::JoinedYestermonth => 5, 
        Statistics::UserCounts::LeftDaily => 2, 
        Statistics::UserCounts::LeftYesterday => 1, 
        Statistics::UserCounts::LeftWeekly => 4, 
        Statistics::UserCounts::LeftYesterweek => 5, 
        Statistics::UserCounts::LeftMonthly => 10, 
        Statistics::UserCounts::LeftYestermonth => 1,
      }
    end

    def get_karma_counts : Hash(KarmaCounts, Int32)
      {
        Statistics::KarmaCounts::TotalUpvotes => 45,
        Statistics::KarmaCounts::TotalDownvotes => 27,
        Statistics::KarmaCounts::UpvotesDaily => 10,
        Statistics::KarmaCounts::UpvotesYesterday => 3,
        Statistics::KarmaCounts::UpvotesWeekly => 14,
        Statistics::KarmaCounts::UpvotesYesterweek => 17,
        Statistics::KarmaCounts::UpvotesMonthly => 32,
        Statistics::KarmaCounts::UpvotesYestermonth => 13,
        Statistics::KarmaCounts::DownvotesDaily => 2,
        Statistics::KarmaCounts::DownvotesYesterday => 4,
        Statistics::KarmaCounts::DownvotesWeekly => 8,
        Statistics::KarmaCounts::DownvotesYesterweek => 10,
        Statistics::KarmaCounts::DownvotesMonthly => 18,
        Statistics::KarmaCounts::DownvotesYestermonth => 9,
      }
    end

    def get_karma_level_count(start_value : Int32, end_value : Int32) : Int32
      arr = [10, 16, 8, 23, 32, 44, 50, 13, -20, -70, -50, 2]

      arr.select{|x| x >= start_value && x < end_value}.size
    end

    def get_robot9000_counts : Hash(Robot9000Counts, Int32)
      {
        Statistics::Robot9000Counts::TotalUnique => 46,
        Statistics::Robot9000Counts::UniqueText => 27,
        Statistics::Robot9000Counts::UniqueMedia => 19,
        Statistics::Robot9000Counts::TotalUnoriginal => 12,
        Statistics::Robot9000Counts::UnoriginalText => 7,
        Statistics::Robot9000Counts::UnoriginalMedia => 5,
      }
    end
  end

  describe Statistics do
    describe "#get_uptime" do
      it "returns time span since class instantiation" do
        start_time = Time.utc 

        stats = MockStatistics.new()

        uptime = stats.get_uptime

        uptime.should(be_a(Time::Span))
        uptime.should(be > Time::Span.new)
      end
    end

    describe "#get_configuration_details" do
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
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new()

        hash = stats.get_configuration_details(services)

        hash[Statistics::BotInfo::RegistrationToggle].should(eq(services.locale.toggle[0]))
        hash[Statistics::BotInfo::MediaLimitPeriod].should(eq(Time::Span.new(hours: 24).to_s))
        hash[Statistics::BotInfo::PseudonymousToggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::SpoilerToggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::KarmaReasonsToggle].should(eq(services.locale.toggle[0]))
        hash[Statistics::BotInfo::Robot9000Toggle].should(eq(services.locale.toggle[1]))
        hash[Statistics::BotInfo::KarmaEconomyToggle].should(eq(services.locale.toggle[0]))
      end
    end

    describe "#get_statistic_screen" do
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
        karma_economy = KarmaHandler.new()

        services = create_services(config: config, karma_economy: karma_economy)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:General, services)

        uptime = Time.utc - start_time

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

        expected = Format.substitute_reply(services.replies.config_stats, {
          "start_date"           => "MOCKED!",
          "days" => uptime.days.to_s,
          "hours" => uptime.hours.to_s,
          "minutes" => uptime.minutes.to_s,
          "seconds" => uptime.seconds.to_s,
          "registration_toggle"  => services.locale.toggle[1],
          "media_limit_period"   => Time::Span.new(hours: 38).to_s,
          "pseudonymous_toggle"  => services.locale.toggle[0],
          "spoilers_toggle"      => services.locale.toggle[1],
          "karma_reasons_toggle" => services.locale.toggle[1],
          "robot9000_toggle"     => services.locale.toggle[0],
          "karma_economy_toggle" => services.locale.toggle[1],
        })

        result.should(eq(expected))
      end

      it "returns formatted message stats screen" do
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:Messages, services)

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
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:Users, services)

        expected = Format.substitute_reply(services.replies.user_stats, {
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
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:Karma, services)

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
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:KarmaLevels, services)

        karma_level_counts = \
          "Junk: 0\n" \
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
        config = HandlerConfig.new(MockConfig.new())
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new()

        result = stats.get_statistic_screen(:Robot9000, services)

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

    describe "#get_percent_change" do
      it "returns the percent change from initial to final value" do
        stats = MockStatistics.new()

        stats.get_percent_change(1, 4).should(eq(300.0))
        stats.get_percent_change(50, 25).should(eq(-50.0))
        stats.get_percent_change(567, 423).should(be_close(-25.4, 0.05))
        stats.get_percent_change(23, 697).should(be_close(2930.4, 0.05))
      end
    end

    describe "#keyboard_markup" do
      it "returns keyboard markup with 3 buttons in rows of three" do 
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Int32 => String))

        services = create_services(config: config)

        stats = MockStatistics.new()

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
        config = HandlerConfig.new(MockConfig.new())
        services = create_services(config: config)

        stats = MockStatistics.new()

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
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Int32 => String))
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
        config = HandlerConfig.new(MockConfig.new())
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new()

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

    describe "#format_config_data" do
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
        karma_economy = KarmaHandler.new()

        services = create_services(config: config, karma_economy: karma_economy)

        stats = MockStatistics.new()

        result = stats.format_config_data(services)

        uptime = Time.utc - start_time

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

        expected = Format.substitute_reply(services.replies.config_stats, {
          "start_date"           => "MOCKED!",
          "days" => uptime.days.to_s,
          "hours" => uptime.hours.to_s,
          "minutes" => uptime.minutes.to_s,
          "seconds" => uptime.seconds.to_s,
          "registration_toggle"  => services.locale.toggle[1],
          "media_limit_period"   => Time::Span.new(hours: 38).to_s,
          "pseudonymous_toggle"  => services.locale.toggle[0],
          "spoilers_toggle"      => services.locale.toggle[1],
          "karma_reasons_toggle" => services.locale.toggle[1],
          "robot9000_toggle"     => services.locale.toggle[0],
          "karma_economy_toggle" => services.locale.toggle[1],
        })

        result.should(eq(expected))
      end
    end

    describe "#format_message_data" do
      it "returns formatted message stats screen" do
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_message_data(services)

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

    describe "#format_user_counts" do
      it "returns formatted user stats screen" do
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_user_counts(services)

        expected = Format.substitute_reply(services.replies.user_stats, {
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

    describe "#format_karma_counts" do
      it "returns formatted karma stats screen" do
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_karma_counts(services)

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

    describe "#format_karma_level_counts" do
      it "returns formatted karma level counts screen" do
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_karma_level_counts(services)

        karma_level_counts = \
          "Junk: 0\n" \
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
        config = HandlerConfig.new(MockConfig.new(karma_levels: {} of Int32 => String))

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_karma_level_counts(services)

        # NOTE: Update if localizing this message
        result.should(eq("No stats available"))
      end
    end

    describe "#format_robot9000_counts" do
      it "returns formatted robot9000 stats screen" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        config = HandlerConfig.new(MockConfig.new())
        r9k = SQLiteRobot9000.new(connection, check_text: true, check_media: true)

        services = create_services(config: config, r9k: r9k)

        stats = MockStatistics.new()

        result = stats.format_robot9000_counts(services)

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
        config = HandlerConfig.new(MockConfig.new())

        services = create_services(config: config)

        stats = MockStatistics.new()

        result = stats.format_robot9000_counts(services)

        # NOTE: Update if localizing this message
        result.should(eq("No stats available"))
      end
    end
  end
end