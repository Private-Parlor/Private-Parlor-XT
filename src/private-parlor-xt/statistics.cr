module PrivateParlorXT
  # A base class statistics module used for calculating and recording data about messages and users
  abstract class Statistics

    # General information about the bot, such as uptime and certain configuration toggles
    enum BotInfo
      DateStarted
      Uptime
      RegistrationToggle
      MediaLimitPeriod
      MessageLifespan
      PseudonymousToggle
      SpoilerToggle
      KarmaReasonsToggle
      Robot9000Toggle
      KarmaEconomyToggle
    end

    # Refers to the counts for each message type, includes the number of total messages 
    # for daily, weekly, and monthly durations
    enum Messages
      TotalMessages
      Albums
      Animations
      Audio
      Contacts
      Documents
      Forwards
      Locations
      Photos
      Polls
      Stickers
      Text
      Venues
      Videos
      VideoNotes
      Voice
      MessagesDaily
      MessagesYesterday
      MessagesWeekly
      MessagesYesterweek
      MessagesMonthly
      MessagesYestermonth
    end

    # Refers to the total number of users and users who joined or left for daily, weekly, and monthly durations
    enum Users
      TotalUsers
      TotalJoined
      TotalLeft
      TotalBlacklisted
      JoinedDaily
      JoinedYesterday
      JoinedWeekly
      JoinedYesterweek
      JoinedMonthly
      JoinedYestermonth
      LeftDaily
      LeftYesterday
      LeftWeekly
      LeftYesterweek
      LeftMonthly
      LeftYestermonth
    end

    # Refers to the total amount of karma given or lost and totals for daily, weekly, and monthly durations
    enum Karma
      TotalUpvotes
      TotalDownvotes
      UpvotesDaily
      UpvotesYesterday
      UpvotesWeekly
      UpvotesYesterweek
      UpvotesMonthly
      UpvotesYestermonth
      DownvotesDaily
      DownvotesYesterday
      DownvotesWeekly
      DownvotesYesterweek
      DownvotesMonthly
      DownvotesYestermonth
    end

    # Refers to the total number of unique messages and unoriginal messages for text and media messages
    enum Robot9000
      TotalUnique
      UniqueText
      UniqueMedia
      TotalUnoriginal
      UnoriginalText
      UnoriginalMedia
    end

    # The available stats screens for the `StatsCommand` and its `Tourmaline::InlineKeyboardMarkup`
    enum StatScreens
      General
      Messages
      Users
      Karma
      KarmaLevels
      Robot9000
    end

    # Get the `Time` the module was initialized, which should coincide closely with the time the bot was started.
    # Used to calculate uptime.
    getter start_time : Time = Time.utc

    # Returns a `Time::Span` containing the amount of time the bot has been running
    def uptime : Time::Span
      Time.utc - @start_time
    end

    # Returns a `String` containing the date at which the statistics module was initialized
    abstract def start_date : String

    # Increment the message count according to the given *type* and increment the total number of messages in general
    abstract def increment_messages(type : Messages) : Nil

    # Increment the number of upvotes given
    abstract def increment_upvotes : Nil

    # Increment the number of downvotes given
    abstract def increment_downvotes : Nil

    # Increment the number of unoriginal text messages encountered
    abstract def increment_unoriginal_text : Nil

    # Increment the number of unoriginal media messages encountered
    abstract def increment_unoriginal_media : Nil

    # Returns a hash of `BotInfo` to `String`, containing information about configuration data and toggles
    def configuration_details(services : Services) : Hash(BotInfo, String)
      {
        BotInfo::RegistrationToggle => services.config.registration_open ? services.locale.toggle[1] : services.locale.toggle[0],
        BotInfo::MediaLimitPeriod   => Format.time_span(services.config.media_limit_period, services.locale),
        BotInfo::MessageLifespan    => services.history.lifespan.zero? ? services.locale.toggle[0] : Format.time_span(services.history.lifespan, services.locale),
        BotInfo::PseudonymousToggle => services.config.pseudonymous ? services.locale.toggle[1] : services.locale.toggle[0],
        BotInfo::SpoilerToggle      => services.config.allow_spoilers ? services.locale.toggle[1] : services.locale.toggle[0],
        BotInfo::KarmaReasonsToggle => services.config.karma_reasons ? services.locale.toggle[1] : services.locale.toggle[0],
        BotInfo::Robot9000Toggle    => services.robot9000.nil? ? services.locale.toggle[0] : services.locale.toggle[1],
        BotInfo::KarmaEconomyToggle => services.karma.nil? ? services.locale.toggle[0] : services.locale.toggle[1],
      }
    end

    # Returns a hash of `Messages` to `Int32`, containing the total number of message for each type and daily, weekly, and monthly totals
    abstract def message_counts : Hash(Messages, Int32)

    # Returns a hash of `Users` to `Int32`, containing the total number of each kind of user and daily, weekly, and monthly totals
    abstract def user_counts : Hash(Users, Int32)

    # Returns a hash of `Karma` to `Int32 , containing the total number of karma given or lost, and daily, weekly, and monthly totals
    abstract def karma_counts : Hash(Karma, Int32)

    # Returns an `Int32` total of users whose karma lie between *start_value* and *end_value*
    abstract def karma_level_count(start_value : Int32, end_value : Int32) : Int32

    # Returns a hash of `Robot9000` to `Int32`, containing the total number of unique and unoriginal messages for texts and media types 
    abstract def robot9000_counts : Hash(Robot9000, Int32)

    # Returns a `String` of the formatted statistics screen based on the given *next_screen*
    def statistic_screen(next_screen : StatScreens, services : Services) : String
      case next_screen
      when StatScreens::General     then config_screen(services)
      when StatScreens::Messages    then messages_screen(services)
      when StatScreens::Users       then full_users_screen(services)
      when StatScreens::Karma       then karma_screen(services)
      when StatScreens::KarmaLevels then karma_levels_screen(services)
      when StatScreens::Robot9000   then robot9000_screen(services)
      else                               ""
      end
    end

    # Returns a `Float64` containing the percent change from *initial* to *final*
    def percent_change(initial : Int32, final : Int32) : Float64
      return final * 100.0 if initial == 0

      ((final - initial) / (initial.abs)) * 100.0
    end

    # Returns the `Tourmaline::InlineKeyboardMarkup` for the given *next_screen*.
    # 
    # Keyboard buttons are localized and displayed in rows of 3 buttons.
    def keyboard_markup(next_screen : StatScreens, services : Services) : Tourmaline::InlineKeyboardMarkup
      options = [StatScreens::General, StatScreens::Messages, StatScreens::Users, StatScreens::Karma]

      unless services.config.karma_levels.empty?
        options << StatScreens::KarmaLevels
      end

      if services.robot9000
        options << StatScreens::Robot9000
      end

      options.delete(next_screen)

      buttons = [] of Tourmaline::InlineKeyboardButton

      options.each do |screen|
        buttons << Tourmaline::InlineKeyboardButton.new(services.locale.statistics_screens[screen], callback_data: "statistics-next=#{screen}")
      end

      # Split buttons into rows of 3 at most
      button_rows = [] of Array(Tourmaline::InlineKeyboardButton)

      buttons.each_slice(3) do |slice|
        button_rows << slice
      end

      Tourmaline::InlineKeyboardMarkup.new(button_rows)
    end

    # Returns a formatted `String` containing information about the bot and its toggles
    def config_screen(services : Services) : String
      start_date = start_date()
      uptime = uptime()
      configuration = configuration_details(services)

      Format.substitute_reply(services.replies.config_stats, {
        "start_date"           => start_date.to_s,
        "days" => uptime.days.to_s,
        "hours" => uptime.hours.to_s,
        "minutes" => uptime.minutes.to_s,
        "seconds" => uptime.seconds.to_s,
        "registration_toggle"  => configuration[BotInfo::RegistrationToggle],
        "media_limit_period"   => configuration[BotInfo::MediaLimitPeriod],
        "message_lifespan"     => configuration[BotInfo::MessageLifespan],
        "pseudonymous_toggle"  => configuration[BotInfo::PseudonymousToggle],
        "spoilers_toggle"      => configuration[BotInfo::SpoilerToggle],
        "karma_reasons_toggle" => configuration[BotInfo::KarmaReasonsToggle],
        "robot9000_toggle"     => configuration[BotInfo::Robot9000Toggle],
        "karma_economy_toggle" => configuration[BotInfo::KarmaEconomyToggle],
      })
    end

    # Returns a formatted `String` containing messages counts
    def messages_screen(services : Services) : String
      totals = message_counts

      daily_change = percent_change(
        totals[Messages::MessagesYesterday],
        totals[Messages::MessagesDaily]
      )

      weekly_change = percent_change(
        totals[Messages::MessagesYesterweek],
        totals[Messages::MessagesWeekly]
      )

      monthly_change = percent_change(
        totals[Messages::MessagesYestermonth],
        totals[Messages::MessagesMonthly]
      )

      Format.substitute_reply(services.replies.message_stats, {
        "total"             => totals[Messages::TotalMessages].to_s,
        "album_total"       => totals[Messages::Albums].to_s,
        "animation_total"   => totals[Messages::Animations].to_s,
        "audio_total"       => totals[Messages::Audio].to_s,
        "contact_total"     => totals[Messages::Contacts].to_s,
        "document_total"    => totals[Messages::Documents].to_s,
        "forward_total"     => totals[Messages::Forwards].to_s,
        "location_total"    => totals[Messages::Locations].to_s,
        "photo_total"       => totals[Messages::Photos].to_s,
        "poll_total"        => totals[Messages::Polls].to_s,
        "sticker_total"     => totals[Messages::Stickers].to_s,
        "text_total"        => totals[Messages::Text].to_s,
        "venue_total"       => totals[Messages::Venues].to_s,
        "video_total"       => totals[Messages::Videos].to_s,
        "video_note_total"  => totals[Messages::VideoNotes].to_s,
        "voice_total"       => totals[Messages::Voice].to_s,
        "daily_total"       => totals[Messages::MessagesDaily].to_s,
        "weekly_total"      => totals[Messages::MessagesWeekly].to_s,
        "monthly_total"     => totals[Messages::MessagesMonthly].to_s,
        "daily_change"      => daily_change.format(decimal_places: 1, only_significant: true),
        "weekly_change"     => weekly_change.format(decimal_places: 1, only_significant: true),
        "monthly_change"    => monthly_change.format(decimal_places: 1, only_significant: true),
        "change_today"      => daily_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "change_this_week"  => weekly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "change_this_month" => monthly_change.positive? ? services.locale.change[1] : services.locale.change[0],
      })
    end

    # Returns a formatted `String` containing user counts
    def full_users_screen(services : Services) : String
      totals = user_counts

      joined_daily_change = percent_change(
        totals[Users::JoinedYesterday],
        totals[Users::JoinedDaily]
      )

      joined_weekly_change = percent_change(
        totals[Users::JoinedYesterweek],
        totals[Users::JoinedWeekly]
      )

      joined_monthly_change = percent_change(
        totals[Users::JoinedYestermonth],
        totals[Users::JoinedMonthly]
      )

      left_daily_change = percent_change(
        totals[Users::LeftYesterday],
        totals[Users::LeftDaily]
      )

      left_weekly_change = percent_change(
        totals[Users::LeftYesterweek],
        totals[Users::LeftWeekly]
      )

      left_monthly_change = percent_change(
        totals[Users::LeftYestermonth],
        totals[Users::LeftMonthly]
      )

      net_daily = totals[Users::JoinedDaily] - totals[Users::LeftDaily]
      net_weekly = totals[Users::JoinedWeekly] - totals[Users::LeftWeekly]
      net_monthly = totals[Users::JoinedMonthly] - totals[Users::LeftMonthly]

      Format.substitute_reply(services.replies.full_user_stats, {
        "total_users"              => totals[Users::TotalUsers].to_s,
        "joined_users"             => totals[Users::TotalJoined].to_s,
        "left_users"               => totals[Users::TotalLeft].to_s,
        "blacklisted_users"        => totals[Users::TotalBlacklisted].to_s,
        "joined_daily_total"       => totals[Users::JoinedDaily].to_s,
        "joined_weekly_total"      => totals[Users::JoinedWeekly].to_s,
        "joined_monthly_total"     => totals[Users::JoinedMonthly].to_s,
        "joined_daily_change"      => joined_daily_change.format(decimal_places: 1, only_significant: true),
        "joined_weekly_change"     => joined_weekly_change.format(decimal_places: 1, only_significant: true),
        "joined_monthly_change"    => joined_monthly_change.format(decimal_places: 1, only_significant: true),
        "joined_change_today"      => joined_daily_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "joined_change_this_week"  => joined_weekly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "joined_change_this_month" => joined_monthly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "left_daily_total"         => totals[Users::LeftDaily].to_s,
        "left_weekly_total"        => totals[Users::LeftWeekly].to_s,
        "left_monthly_total"       => totals[Users::LeftMonthly].to_s,
        "left_daily_change"        => left_daily_change.format(decimal_places: 1, only_significant: true),
        "left_weekly_change"       => left_weekly_change.format(decimal_places: 1, only_significant: true),
        "left_monthly_change"      => left_monthly_change.format(decimal_places: 1, only_significant: true),
        "left_change_today"        => left_daily_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "left_change_this_week"    => left_weekly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "left_change_this_month"   => left_monthly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "net_daily"                => net_daily.to_s,
        "net_weekly"               => net_weekly.to_s,
        "net_monthly"              => net_monthly.to_s,
      })
    end

    # Returns a formatted `String` containing a counts of user totals
    def users_screen(services : Services) : String
      totals = user_counts

      net_daily = totals[Users::JoinedDaily] - totals[Users::LeftDaily]
      net_weekly = totals[Users::JoinedWeekly] - totals[Users::LeftWeekly]
      net_monthly = totals[Users::JoinedMonthly] - totals[Users::LeftMonthly]

      Format.substitute_reply(services.replies.user_stats, {
        "total_users"              => totals[Users::TotalUsers].to_s,
        "net_daily"                => net_daily.to_s,
        "net_weekly"               => net_weekly.to_s,
        "net_monthly"              => net_monthly.to_s,
      })
    end

    # Returns a formatted `String` containing karma counts
    def karma_screen(services : Services) : String
      totals = karma_counts

      upvotes_daily_change = percent_change(
        totals[Karma::UpvotesYesterday],
        totals[Karma::UpvotesDaily]
      )

      upvotes_weekly_change = percent_change(
        totals[Karma::UpvotesYesterweek],
        totals[Karma::UpvotesWeekly]
      )

      upvotes_monthly_change = percent_change(
        totals[Karma::UpvotesYestermonth],
        totals[Karma::UpvotesMonthly]
      )

      downvotes_daily_change = percent_change(
        totals[Karma::DownvotesYesterday],
        totals[Karma::DownvotesDaily]
      )

      downvotes_weekly_change = percent_change(
        totals[Karma::DownvotesYesterweek],
        totals[Karma::DownvotesWeekly]
      )

      downvotes_monthly_change = percent_change(
        totals[Karma::DownvotesYestermonth],
        totals[Karma::DownvotesMonthly]
      )

      Format.substitute_reply(services.replies.karma_stats, {
        "upvotes"                    => totals[Karma::TotalUpvotes].to_s,
        "downvotes"                  => totals[Karma::TotalDownvotes].to_s,
        "upvote_daily_total"         => totals[Karma::UpvotesDaily].to_s,
        "upvote_weekly_total"        => totals[Karma::UpvotesWeekly].to_s,
        "upvote_monthly_total"       => totals[Karma::UpvotesMonthly].to_s,
        "upvote_daily_change"        => upvotes_daily_change.format(decimal_places: 1, only_significant: true),
        "upvote_weekly_change"       => upvotes_weekly_change.format(decimal_places: 1, only_significant: true),
        "upvote_monthly_change"      => upvotes_monthly_change.format(decimal_places: 1, only_significant: true),
        "upvote_change_today"        => upvotes_daily_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "upvote_change_this_week"    => upvotes_weekly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "upvote_change_this_month"   => upvotes_monthly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "downvote_daily_total"       => totals[Karma::DownvotesDaily].to_s,
        "downvote_weekly_total"      => totals[Karma::DownvotesWeekly].to_s,
        "downvote_monthly_total"     => totals[Karma::DownvotesMonthly].to_s,
        "downvote_daily_change"      => downvotes_daily_change.format(decimal_places: 1, only_significant: true),
        "downvote_weekly_change"     => downvotes_weekly_change.format(decimal_places: 1, only_significant: true),
        "downvote_monthly_change"    => downvotes_monthly_change.format(decimal_places: 1, only_significant: true),
        "downvote_change_today"      => downvotes_daily_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "downvote_change_this_week"  => downvotes_weekly_change.positive? ? services.locale.change[1] : services.locale.change[0],
        "downvote_change_this_month" => downvotes_monthly_change.positive? ? services.locale.change[1] : services.locale.change[0],
      })
    end

    # Returns a formatted `String` containing karma level counts
    def karma_levels_screen(services : Services) : String
      if services.config.karma_levels.empty?
        return services.replies.no_stats_available
      end

      levels = services.config.karma_levels

      karma_records = ""

      levels.each do |range, level|
        count = karma_level_count(range.begin, range.end)
        karma_records += "#{level}: #{count}\n"
      end

      Format.substitute_reply(services.replies.karma_level_stats, {
        "karma_levels" => karma_records,
      })
    end

    # Returns a formatted `String` containing Robot9000 counts
    def robot9000_screen(services : Services) : String
      unless services.robot9000
        return services.replies.no_stats_available
      end

      totals = robot9000_counts

      Format.substitute_reply(services.replies.robot9000_stats, {
        "total_unique"     => totals[Robot9000::TotalUnique].to_s,
        "unique_text"      => totals[Robot9000::UniqueText].to_s,
        "unique_media"     => totals[Robot9000::UniqueMedia].to_s,
        "total_unoriginal" => totals[Robot9000::TotalUnoriginal].to_s,
        "unoriginal_text"  => totals[Robot9000::UnoriginalText].to_s,
        "unoriginal_media" => totals[Robot9000::UnoriginalMedia].to_s,
      })
    end
  end
end
