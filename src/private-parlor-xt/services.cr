require "./config/handler_config.cr"
require "./locale/*"
require "./database.cr"
require "./history.cr"
require "./ranks/authorized_ranks.cr"
require "./client.cr"
require "./relay/relay.cr"
require "./spam/spam_handler.cr"

module PrivateParlorXT
  # Container for all objects needed for handlers
  class Services
    # Returns the `HandlerConfig` object
    getter config : HandlerConfig

    # Returns the `Locale` object
    getter locale : Locale

    # Returns the `Replies` object
    getter replies : Replies

    # Returns the `Logs` object
    getter logs : Logs

    # Returns the `CommandDescriptions` object
    getter command_descriptions : CommandDescriptions

    # Returns the `Database` object
    getter database : Database

    # Retruns the `History` object
    getter history : History

    # Retrusn the `AuthorizedRanks` object
    getter access : AuthorizedRanks

    # Returns the `Relay` object
    getter relay : Relay

    # Returns the `SpamHandler` object if it is available
    getter spam : SpamHandler?

    # Returns the `Robot9000` object if it is available
    getter robot9000 : Robot9000?

    # Returns the `KarmaHandler` object if it is available
    getter karma : KarmaHandler?

    # Returns the `Statistics` object if it is available
    getter stats : Statistics?

    # Creates an instance of `Services`.
    #
    # ## Arguments:
    #
    # `config`
    # :     `HandlerConfig` object with a limited set of configuration values to be used in subclasses of `Handler` and `CallbackHandler`
    #
    # `locale`
    # :     `Locale`, general localized values from a locale file
    #
    # `replies`
    # :     `Replies`, system message replies from a locale file
    #
    # `logs`
    # :     `Logs`, log messages from a locale file
    #
    # `command_descriptions`
    # :     `CommandDescriptions`, descriptions for commands from a locale file
    # 
    # `database`
    # :     `Database` object
    # 
    # `history`
    # :     message `History` object
    #
    # `access`
    # :     `AuthorizedRanks` module used to ensure authorized use of commands and messages
    # 
    # `relay`
    # :     `Relay` object for queueing messages and sending them to Telegram
    # 
    # `spam`
    # :     `SpamHandler` object preventing message spam, if this module is toggled
    #
    # `robot9000`
    # :     `Robot9000` object ensure message uniqueness, if this module is toggled
    # 
    # `karma`
    # :     `KarmaHandler` object that requires users to have karma in order to send messages, if this module is toggled
    # 
    # `stats`
    # :     `Statistics` object that records data about the bot, if this module is toggled
    def initialize(
      @config : HandlerConfig,
      @locale : Locale,
      @replies : Replies,
      @logs : Logs,
      @command_descriptions : CommandDescriptions,
      @database : Database,
      @history : History,
      @access : AuthorizedRanks,
      @relay : Relay,
      @spam : SpamHandler? = nil,
      @robot9000 : Robot9000? = nil,
      @karma : KarmaHandler? = nil,
      @stats : Statistics? = nil
    )
    end

    # Creates a new instance of `Services` from a `Config` file
    def initialize(config : Config, client : Client)
      localization = Localization.parse_locale(Path["./locales"], config.locale)

      @config = HandlerConfig.new(config)
      @locale = localization.locale
      @replies = localization.replies
      @logs = localization.logs
      @command_descriptions = localization.command_descriptions
      
      connection = DB.open("sqlite3://#{config.database}")

      @database = SQLiteDatabase.new(connection)

      if config.database_history
        @history = SQLiteHistory.new(config.message_lifespan.hours, connection)
      else
        @history = CachedHistory.new(config.message_lifespan.hours)
      end

      @access = AuthorizedRanks.new(config.ranks)

      @relay = Relay.new(config.log_channel, client)

      if config.spam_interval != 0
        @spam = config.spam_handler
      else
        @spam = nil
      end

      if config.toggle_r9k_media || config.toggle_r9k_text
        @robot9000 = SQLiteRobot9000.new(
          connection,
          config.valid_codepoints,
          config.toggle_r9k_text,
          config.toggle_r9k_media,
          config.toggle_r9k_forwards,
          config.r9k_warn,
          config.r9k_cooldown,
        )
      else
        @robot9000 = nil
      end

      if config.karma_economy
        @karma = config.karma_economy
      end

      if config.statistics
        @stats = SQLiteStatistics.new(connection)
      end
    end
  end
end
