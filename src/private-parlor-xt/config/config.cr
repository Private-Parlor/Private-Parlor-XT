require "../ranks/rank.cr"
require "../spam/spam_handler.cr"
require "yaml"
require "log"

module PrivateParlorXT

  # A container for values deserialized from the configuration file
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "token")]
    # The API token obtained from @BotFather
    getter token : String

    @[YAML::Field(key: "database")]
    # A file path to a SQLite datbase
    getter database : String

    @[YAML::Field(key: "locale")]
    # The language tag for Private Parlor's language/locale
    getter locale : String = "en-US"

    @[YAML::Field(key: "log_level")]
    # The level of severity for log messages
    getter log_level : Log::Severity = Log::Severity::Info

    @[YAML::Field(key: "log_file")]
    # A file path to an optional log file
    getter log_file : String? = nil

    @[YAML::Field(key: "log_channel")]
    # A Telegram ID of a channel to output bot logs to 
    getter log_channel : String = ""

    @[YAML::Field(key: "message_lifespan")]
    # The amount of time a message can exist before expiring and being deleted from the cache
    property message_lifespan : Int32 = 24

    @[YAML::Field(key: "database_history")]
    # Whether or not to use the database for persisting message history
    getter database_history : Bool? = false

    @[YAML::Field(key: "media_spoilers")]
    # Whether or not to allow users to send photos, videos, or GIFs with a spoiler overlay
    getter media_spoilers : Bool? = false

    @[YAML::Field(key: "karma_reasons")]
    # Whether or not to allow users to attach a reason to their upvote/downvote messages
    getter karma_reasons : Bool? = false

    @[YAML::Field(key: "regular_forwards")]
    # Whether or not to relay forwarded messages as though a `PhotoHandler`, `TextHandler`, or similar `UpdateHandler` got them
    getter regular_forwards : Bool? = false

    @[YAML::Field(key: "inactivity_limit")]
    # The limit (in days) for which a user can be inactive and still receive messages
    getter inactivity_limit : Int32 = 0

    @[YAML::Field(key: "linked_network")]
    # A `String` or hash of linked network strings deserialized from the config file that will be processed and used to set `linked_network`
    getter intermediary_linked_network : Hash(String, String) | String | Nil

    @[YAML::Field(ignore: true)]
    # A hash of `String` => `String` mapping the name of a chat to the chat's username
    getter linked_network : Hash(String, String) = {} of String => String

    @[YAML::Field(key: "ranks")]
    # A mapping of `Rank` recognized by the bot
    property ranks : Hash(Int32, Rank) = {
      -10 => Rank.new(
        "Banned",
        Set.new([] of CommandPermissions),
        Set.new([] of MessagePermissions)
      ),
    }

    @[YAML::Field(key: "default_rank")]
    # The value of the `Rank` a user will be set to when joining for the first time, getting demoted, or when one of the `ranks` are invalid
    property default_rank : Int32 = 0

    @[YAML::Field(key: "karma_levels")]
    # A hash of `Int32` => `String` mapping the start of a karma level to the name of that level, which will be processed into ranges for `karma_levels`
    getter intermediate_karma_levels : Hash(Int32, String) = {} of Int32 => String

    @[YAML::Field(ignore: true)]
    # A hash of `Range(Int32, Int32)` => `String` mapping a range of possible `User` karma values to the name of the karma level that is defined by that range
    property karma_levels : Hash(Range(Int32, Int32), String) = {} of Range(Int32, Int32) => String

    @[YAML::Field(key: "toggle_r9k_text")]
    # Toggle ROBOT9000 for text and captions
    getter toggle_r9k_text : Bool? = false

    @[YAML::Field(key: "toggle_r9k_media")]
    # Toggle ROBOT9000 for media
    getter toggle_r9k_media : Bool? = false

    @[YAML::Field(key: "toggle_r9k_forwards")]
    # Toggle ROBOT9000 for forwards; checks the text and media for forwards if both/either `toggle_r9k_text` and/or `toggle_r9k_media` are enabled
    getter toggle_r9k_forwards : Bool? = false

    @[YAML::Field(key: "r9k_cooldown")]
    # Cooldown length (in seconds) for when a user sends an unoriginal message
    getter r9k_cooldown : Int32 = 0

    @[YAML::Field(key: "r9k_warn")]
    # Whether or not to give the user a warning for sending an unoriginal message and cooldown according to the number of warnings
    getter r9k_warn : Bool? = false

    @[YAML::Field(key: "valid_codepoints")]
    # An array of, what should be, 2-element arrays containing the start and end of codepoint ranges that are valid for ROBOT9000 text checks, which will be processed into ranges for `valid_codepoints`
    getter intermediate_valid_codepoints : Array(Array(Int32))?

    @[YAML::Field(ignore: true)]
    # An array of `Range(Int32, Int32)` containing valid codepoints for ROBOT9000 text checks; characters in text that lie outside these ranges will signal that the text is invalid. Defaults to the ASCII character range
    property valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)]

    # Command Toggles

    @[YAML::Field(key: "enable_start")]
    # A 2-element array, the first element enables the `StartCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_start : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_stop")]
    # A 2-element array, the first element enables the `StopCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_stop : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_info")]
    # A 2-element array, the first element enables the `InfoCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_info : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_users")]
    # A 2-element array, the first element enables the `UsersCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_users : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_version")]
    # A 2-element array, the first element enables the `VersionCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_version : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_toggle_karma")]
    # A 2-element array, the first element enables the `ToggleKarmaCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_toggle_karma : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_toggle_debug")]
    # A 2-element array, the first element enables the `ToggleDebugCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_toggle_debug : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_reveal")]
    # A 2-element array, the first element enables the `RevealCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_reveal : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_tripcode")]
    # A 2-element array, the first element enables the `TripcodeCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_tripcode : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_sign")]
    # A 2-element array, the first element enables the `SignCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_sign : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_tripsign")]
    # A 2-element array, the first element enables the `TripcodeSignCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_tripsign : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_karma_sign")]
    # A 2-element array, the first element enables the `KarmaSignCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_karma_sign : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_ranksay")]
    # A 2-element array, the first element enables the `RanksayCommand` (and all the generated rankname *say commands) and the second registers its `CommandDescriptions` with @BotFather
    getter enable_ranksay : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_motd")]
    # A 2-element array, the first element enables the `MotdCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_motd : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_help")]
    # A 2-element array, the first element enables the `HelpCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_help : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_upvotes")]
    # A 2-element array, the first element enables the `UpvoteHandler`, the second does nothing for now as this command is not a `CommandHandler`
    getter enable_upvote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_downvotes")]
    # A 2-element array, the first element enables the `DownvoteHandler`, the second does nothing for now as this command is not a `CommandHandler`
    getter enable_downvote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_promote")]
    # A 2-element array, the first element enables the `PromoteCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_promote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_demote")]
    # A 2-element array, the first element enables the `DemoteCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_demote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_warn")]
    # A 2-element array, the first element enables the `WarnCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_warn : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_delete")]
    # A 2-element array, the first element enables the `DeleteCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_delete : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_uncooldown")]
    # A 2-element array, the first element enables the `UncooldownCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_uncooldown : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_remove")]
    # A 2-element array, the first element enables the `RemoveCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_remove : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_purge")]
    # A 2-element array, the first element enables the `PurgeCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_purge : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_blacklist")]
    # A 2-element array, the first element enables the `BlacklistCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_blacklist : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_unblacklist")]
    # A 2-element array, the first element enables the `UnblacklistCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_unblacklist : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_whitelist")]
    # A 2-element array, the first element enables the `WhitelistCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_whitelist : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_spoiler")]
    # A 2-element array, the first element enables the `SpoilerCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_spoiler : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_karma_info")]
    # A 2-element array, the first element enables the `KarmaInfoCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_karma_info : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_pin")]
    # A 2-element array, the first element enables the `PinCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_pin : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_unpin")]
    # A 2-element array, the first element enables the `UnpinCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_unpin : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_stats")]
    # A 2-element array, the first element enables the `StatsCommand` and the second registers its `CommandDescriptions` with @BotFather
    getter enable_stats : Array(Bool) = [false, false]

    # Relay Toggles

    @[YAML::Field(key: "relay_text")]
    # Whether or not to relay text messages and enable the `TextHandler`
    getter relay_text : Bool? = true

    @[YAML::Field(key: "relay_animation")]
    # Whether or not to relay animations/GIFs and enable the `AnimationHandler`
    getter relay_animation : Bool? = true

    @[YAML::Field(key: "relay_audio")]
    # Whether or not to relay audio messages and enable the `AudioHandler`
    getter relay_audio : Bool? = true

    @[YAML::Field(key: "relay_document")]
    # Whether or not to relay documents and files and enable the `DocumentHandler`
    getter relay_document : Bool? = true

    @[YAML::Field(key: "relay_video")]
    # Whether or not to relay videos and enable the `VideoHandler`
    getter relay_video : Bool? = true

    @[YAML::Field(key: "relay_video_note")]
    # Whether or not to relay video note messages and enable the `VideoNoteHandler`
    getter relay_video_note : Bool? = true

    @[YAML::Field(key: "relay_voice")]
    # Whether or not to relay voice messages and enable the `VoiceHandler`
    getter relay_voice : Bool? = true

    @[YAML::Field(key: "relay_photo")]
    # Whether or not to relay photos and enable the `PhotoHandler`
    getter relay_photo : Bool? = true

    @[YAML::Field(key: "relay_media_group")]
    # Whether or not to relay albums and enable the `AlbumHandler`
    getter relay_media_group : Bool? = true

    @[YAML::Field(key: "relay_poll")]
    # Whether or not to relay polls and enable the `PollHandler`
    getter relay_poll : Bool? = true

    @[YAML::Field(key: "relay_forwarded_message")]
    # Whether or not to relay forwarded messages and enable the `ForwardHandler`
    getter relay_forwarded_message : Bool? = true

    @[YAML::Field(key: "relay_sticker")]
    # Whether or not to relay stickers and enable the `StickerHandler`
    getter relay_sticker : Bool? = true

    @[YAML::Field(key: "relay_venue")]
    # Whether or not to relay venues and enable the `VenueHandler`
    getter relay_venue : Bool? = false

    @[YAML::Field(key: "relay_location")]
    # Whether or not to relay location messages and enable the `LocationHandler`
    getter relay_location : Bool? = false

    @[YAML::Field(key: "relay_contact")]
    # Whether or not to relay contacts and enable the `ContactHandler`
    getter relay_contact : Bool? = false

    @[YAML::Field(key: "cooldown_base")]
    # The base integer for which cooldown times are computed from
    getter cooldown_base : Int32 = 5

    @[YAML::Field(key: "warn_lifespan")]
    # The length of time (in hours) until a warning expires
    getter warn_lifespan : Int32 = 7 * 24

    @[YAML::Field(key: "warn_deduction")]
    # The amount of karma to remove from a user when receiving a cooldown
    getter warn_deduction : Int32 = 10

    @[YAML::Field(key: "karma_economy")]
    # A `KarmaHandler`, which manages what a user can post based on how much karma he has
    getter karma_economy : KarmaHandler?

    @[YAML::Field(key: "spam_interval")]
    # The amount of time (in seconds) between spam score reductions
    getter spam_interval : Int32 = 10

    @[YAML::Field(key: "spam_handler")]
    # A `SpamHandler`, which manages how much a user can post within a duration of time
    getter spam_handler : SpamHandler

    @[YAML::Field(key: "media_limit_period")]
    # The duration (in hours) in which new users cannot send media
    getter media_limit_period : Int32 = 0

    @[YAML::Field(key: "registration_open")]
    # Whether or not registration is open, allowing new users to join
    getter registration_open : Bool? = true

    @[YAML::Field(key: "pseudonymous")]
    # Whether or not to enable pseudonymous mode, which forces the use of tripcodes for all users and automatically prepends messages with the user's tripcode
    getter pseudonymous : Bool? = false

    @[YAML::Field(key: "flag_signatures")]
    # Whether or not to replace tripcodes with a flag or emoji signature
    getter flag_signatures : Bool? = false

    @[YAML::Field(key: "statistics")]
    # Whether or not to enable the recording of message statistics to be viewed later using the `StatsCommand`
    getter statistics : Bool? = false

    @[YAML::Field(key: "blacklist_contact")]
    # The contact string shown to blacklisted users
    getter blacklist_contact : String? = nil

    @[YAML::Field(key: "sign_limit_interval")]
    # Limit a users' usage of `SignCommand` and `TripodeSignCommand` for once every interval (in seconds)
    getter sign_limit_interval : Int32 = 600

    @[YAML::Field(key: "upvote_limit_interval")]
    # Limit a user's usage of `UpvoteHandler` for once every interval (in seconds)
    getter upvote_limit_interval : Int32 = 0

    @[YAML::Field(key: "downvote_limit_interval")]
    # Limit a user's usage of `DownvoteHandler` for once every interval (in seconds)
    getter downvote_limit_interval : Int32 = 0

    @[YAML::Field(key: "smileys")]
    # An array of emoticons shown in `InfoCommand` messages that start out happy and get sadder based on the number of user warnings
    property smileys : Array(String) = [":)", ":|", ":/", ":("]

    @[YAML::Field(key: "strip_format")]
    # An array of `String` referring to entity types that will be removed from all messages
    property entities : Array(String) = ["bold", "italic", "text_link"]

    @[YAML::Field(key: "tripcode_salt")]
    # A `String` used to generate secure tripcodes
    getter salt : String = ""

    # Deserializes the values from the config file and returns a validated `Config`
    def self.parse_config : Config
      check_config(Config.from_yaml(File.open("config.yaml")))
    rescue ex : YAML::ParseException
      Log.error(exception: ex) { "Could not parse the given value at row #{ex.line_number}. This could be because a required value was not set or the wrong type was given." }
      exit
    rescue ex : File::NotFoundError | File::AccessDeniedError
      Log.error(exception: ex) { "Could not open \"./config.yaml\". Exiting..." }
      exit
    end

    # Validates the values retrieved from the config file and updates the values in *config* if they are invalid
    private def self.check_config(config : Config) : Config
      message_entities = ["bold", "italic", "underline", "strikethrough", "spoiler", "code", "text_link", "custom_emoji", "blockquote"]

      if config.smileys.size != 4
        Log.notice { "Not enough or too many smileys. Should be four, was #{config.smileys}; defaulting to [:), :|, :/, :(]" }
        config.smileys = [":)", ":|", ":/", ":("]
      end

      if (config.entities & message_entities).size != config.entities.size
        Log.notice { "Could not determine strip_format, was #{config.entities}; check for duplicates or mispellings. Using defaults." }
        config.entities = ["bold", "italic", "text_link"]
      end

      set_log(config)
      validate_prerequisites(config)
      config = check_and_init_ranks(config)
      config = init_karma_levels(config)
      config = init_valid_codepoints(config)
      config = check_and_init_linked_network(config)
    end

    # Checks every intermediate rank for invalid or otherwise undefined permissions
    # and initializes the Ranks hash
    #
    # Returns an updated `Config` object
    private def self.check_and_init_ranks(config : Config) : Config
      promote_keys = Set{
        CommandPermissions::Promote,
        CommandPermissions::PromoteLower,
        CommandPermissions::PromoteSame,
      }

      ranksay_keys = Set{
        CommandPermissions::Ranksay,
        CommandPermissions::RanksayLower,
      }

      if config.ranks[config.default_rank]? == nil
        Log.notice { "Default rank #{config.default_rank} does not exist in ranks, using User with rank 0 as default" }
        config.default_rank = 0

        config.ranks[0] = Rank.new(
          "User",
          Set{
            CommandPermissions::Upvote, CommandPermissions::Downvote, CommandPermissions::Sign, CommandPermissions::TSign,
          },
          Set{
            MessagePermissions::Text, MessagePermissions::Animation, MessagePermissions::Audio, MessagePermissions::Document,
            MessagePermissions::Video, MessagePermissions::VideoNote, MessagePermissions::Voice, MessagePermissions::Photo,
            MessagePermissions::MediaGroup, MessagePermissions::Poll, MessagePermissions::Forward, MessagePermissions::Sticker,
            MessagePermissions::Venue, MessagePermissions::Location, MessagePermissions::Contact,
          }
        )
      end

      config.ranks.each do |key, rank|
        permissions = rank.command_permissions
        if (invalid_promote = rank.command_permissions & promote_keys) && invalid_promote.size > 1
          Log.notice {
            "Removed the following mutually exclusive permissions from Rank #{rank.name}: [#{invalid_promote.join(", ")}]"
          }
          permissions = rank.command_permissions - promote_keys
        end
        if (invalid_ranksay = rank.command_permissions & ranksay_keys) && invalid_ranksay.size > 1
          Log.notice {
            "Removed the following mutually exclusive permissions from Rank #{rank.name}: [#{invalid_ranksay.join(", ")}]"
          }
          permissions = rank.command_permissions - ranksay_keys
        end

        config.ranks[key] = Rank.new(rank.name, permissions, rank.message_permissions)
      end

      validate_permissions(config)
    end

    # Checks that each `Rank` permission in `ranks` is useable, such that the command or update handler is enabled for that permission to be used
    # 
    # If a permission is found and the associated handler is not enabled, it creates a new `Rank` without that permission and logs the problem
    private def self.validate_permissions(config : Config) : Config
      command_permissions = {
        CommandPermissions::Users => config.enable_users[0],
        CommandPermissions::Upvote => config.enable_upvote[0],
        CommandPermissions::Downvote => config.enable_downvote[0],
        CommandPermissions::Promote => config.enable_promote[0],
        CommandPermissions::PromoteLower => config.enable_promote[0],
        CommandPermissions::PromoteSame => config.enable_promote[0],
        CommandPermissions::Demote => config.enable_demote[0],
        CommandPermissions::Sign => config.enable_sign[0],
        CommandPermissions::TSign => config.enable_tripsign[0],
        CommandPermissions::Reveal => config.enable_reveal[0],
        CommandPermissions::Spoiler => config.enable_spoiler[0],
        CommandPermissions::Pin => config.enable_pin[0],
        CommandPermissions::Unpin => config.enable_unpin[0],
        CommandPermissions::Ranksay => config.enable_ranksay[0],
        CommandPermissions::RanksayLower => config.enable_ranksay[0],
        CommandPermissions::Warn => config.enable_warn[0],
        CommandPermissions::Delete => config.enable_delete[0],
        CommandPermissions::Uncooldown => config.enable_uncooldown[0],
        CommandPermissions::Remove => config.enable_remove[0],
        CommandPermissions::Purge => config.enable_purge[0],
        CommandPermissions::Blacklist => config.enable_blacklist[0],
        CommandPermissions::Whitelist => config.enable_whitelist[0],
        CommandPermissions::MotdSet => config.enable_motd[0],
        CommandPermissions::RankedInfo => config.enable_info[0],
        CommandPermissions::Unblacklist => config.enable_unblacklist[0],
      }

      message_permissions = {
        MessagePermissions::Text => config.relay_text,
        MessagePermissions::Animation => config.relay_animation,
        MessagePermissions::Audio => config.relay_audio,
        MessagePermissions::Document => config.relay_document,
        MessagePermissions::Video => config.relay_video,
        MessagePermissions::VideoNote => config.relay_video_note,
        MessagePermissions::Voice => config.relay_voice,
        MessagePermissions::Photo => config.relay_photo,
        MessagePermissions::MediaGroup => config.relay_media_group,
        MessagePermissions::Poll => config.relay_poll,
        MessagePermissions::Forward => config.relay_forwarded_message,
        MessagePermissions::Sticker => config.relay_sticker,
        MessagePermissions::Venue => config.relay_venue,
        MessagePermissions::Location => config.relay_location,
        MessagePermissions::Contact => config.relay_contact,
      }

      config.ranks.each do |key, rank|
        extraneous_commands = Set(CommandPermissions).new
        extraneous_messages = Set(MessagePermissions).new

        rank.command_permissions.each do |permission|
          next if command_permissions[permission]

          extraneous_commands.add(permission)
        end

        rank.message_permissions.each do |permission|
          next if message_permissions[permission]


          extraneous_messages.add(permission)
        end

        relevant_permissions = extraneous_commands.empty? && extraneous_messages.empty?

        next if relevant_permissions

        config.ranks[key] = Rank.new(
          rank.name,
          rank.command_permissions - extraneous_commands,
          rank.message_permissions - extraneous_messages,
        )

        permissions = extraneous_commands.map(&.to_s) + extraneous_messages.map(&.to_s)

        Log.notice {"The permissions #{permissions} for rank '#{rank.name}' were ignored as the revelant handlers were not enabled"}
      end

      config
    end

    # Checks the config for entries that are enabled but require another entry to be enabled to function
    # 
    # If an entry that depends on another is found, it logs the problem
    private def self.validate_prerequisites(config : Config) : Nil
      if config.media_spoilers
        unless (config.relay_photo || config.relay_video || config.relay_animation || config.relay_media_group)
          Log.info {"Media spoilers are enabled, but neither photos nor videos nor animations nor media groups are enabled"}
        end
      end

      if config.karma_reasons
        unless (config.enable_upvote[0] || config.enable_downvote[0])
          Log.info {"Karma reasons are enabled, but neither upvotes nor downvotes are enabled, so karma reasons cannot be used"}
        end
      end

      if config.regular_forwards
        unless config.relay_forwarded_message
          Log.info {"Regular forwards are enabled, but forwarded messages are not, so the bot cannot relay regular forwards"}
        end
      end

      if config.toggle_r9k_forwards
        unless (config.toggle_r9k_text || config.toggle_r9k_media)
          Log.info {"R9K forwards are enabled, but neither R9K text nor R9K media are enabled, so ROBOT9000 is not enbaled"}
        end
      end

      if config.enable_whitelist[0]
        if config.registration_open
          Log.info {"The whitelist command is enabled, but registration is open; the command is unecessary"}
        end
      end

      if config.pseudonymous
        unless config.enable_tripcode[0]
          Log.info {"Pseudonymous mode is enabled, but the tripcode command is disabled. It will not be possible to set a tripcode"}
        end
      end

      if config.statistics
        unless config.enable_stats[0]
          Log.info {"Statistics are enabled, but the stats command is disabled. It will not be possible to view the statisitics"}
        end
      end

      if config.r9k_warn 
        if config.r9k_cooldown > 0
          Log.info {"R9K Warn and R9K Cooldown are both enabled; only R9K Cooldown will apply if ROBOT9000 is enabled"}
        end
      end
    end

    # Validate `intermediate_karma_levels` and set `karma_levels`
    private def self.init_karma_levels(config : Config) : Config
      return config if config.intermediate_karma_levels.empty?

      case config.intermediate_karma_levels.size
      when 1
        keys = config.intermediate_karma_levels.keys

        config.karma_levels = {(Int32::MIN..Int32::MAX) => config.intermediate_karma_levels[keys[0]]}
      when 2
        keys = config.intermediate_karma_levels.keys.sort!

        config.karma_levels = {
          (Int32::MIN...keys[1]) => config.intermediate_karma_levels[keys[0]],
          (keys[1]..Int32::MAX) => config.intermediate_karma_levels[keys[1]]
        }
      else
        keys = config.intermediate_karma_levels.keys.sort!

        levels = {} of Range(Int32, Int32) => String

        keys.each_cons_pair do |low, high|
          if low == keys[0]
            levels[(Int32::MIN...high)] = config.intermediate_karma_levels[low]
          elsif high == keys[-1]
            levels[(low...high)] = config.intermediate_karma_levels[low]
            levels[(high..Int32::MAX)] = config.intermediate_karma_levels[high]
          else
            levels[(low...high)] = config.intermediate_karma_levels[low]
          end
        end

        config.karma_levels = levels
      end

      config
    end

    # Validate `intermediate_valid_codepoints` and set `valid_codepoints`
    private def self.init_valid_codepoints(config : Config) : Config
      unless codepoint_tuples = config.intermediate_valid_codepoints
        return config
      end

      ranges = [] of Range(Int32, Int32)
      codepoint_tuples.each do |tuple|
        ranges << Range.new(tuple[0], tuple[1])
      end

      config.valid_codepoints = ranges

      config
    end

    # Checks the config for a hash of linked networks and initializes `linked_network` field.
    #
    # If `intermediary_linked_network` is a hash, merge it into `linked_network`
    #
    # Otherwise if it is a string, try to open the file from the path and merge
    # the YAML dictionary there into `linked_network`
    private def self.check_and_init_linked_network(config : Config) : Config
      if (links = config.intermediary_linked_network) && links.is_a?(String)
        begin
          hash = {} of String => String
          File.open(links) do |file|
            yaml = YAML.parse(file)
            yaml["linked_network"].as_h.each do |k, v|
              hash[k.as_s] = v.as_s
            end
            config.linked_network.merge!(hash)
          end
        rescue ex : YAML::ParseException
          Log.error(exception: ex) { "Could not parse the given value at row #{ex.line_number}. Check that \"linked_network\" is a valid dictionary." }
        rescue ex : File::NotFoundError | File::AccessDeniedError
          Log.error(exception: ex) { "Could not open linked network file, \"#{links}\"" }
        end
      elsif links.is_a?(Hash(String, String))
        config.linked_network.merge!(links)
      end

      config
    end

    # Reset log with the severity level defined in `config.yaml`.
    #
    # A file can also be used to store log output. If the file does not exist, a new one will be made.
    private def self.set_log(config : Config) : Nil
      # Skip setup if default values were given
      if config.log_level == Log::Severity::Info && config.log_file == nil
        return
      end

      # Reset log with log level; outputting to a file if a path was given
      Log.setup do |log|
        if path = config.log_file
          begin
            if File.file?(path) # If log file already exists
              file = Log::IOBackend.new(File.open(path, "a+"))
            else # Log file does not exist, make one
              file = Log::IOBackend.new(File.new(path, "a+"))
            end
          rescue ex : File::NotFoundError | File::AccessDeniedError
            Log.error(exception: ex) { "Could not open/create log file" }
          end

          log.bind("*", config.log_level, file) if file
        end

        log.bind("*", config.log_level, Log::IOBackend.new)
      end
    end
  end
end
