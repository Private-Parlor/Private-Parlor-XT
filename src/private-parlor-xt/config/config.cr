require "../ranks/rank.cr"
require "../spam/spam_handler.cr"
require "yaml"
require "log"

module PrivateParlorXT
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "token")]
    getter token : String

    @[YAML::Field(key: "database")]
    getter database : String

    @[YAML::Field(key: "locale")]
    getter locale : String = "en-US"

    @[YAML::Field(key: "log_level")]
    getter log_level : Log::Severity = Log::Severity::Info

    @[YAML::Field(key: "log_file")]
    getter log_file : String? = nil

    @[YAML::Field(key: "log_channel")]
    getter log_channel : String = ""

    @[YAML::Field(key: "message_lifespan")]
    property message_lifespan : Int32 = 24

    @[YAML::Field(key: "database_history")]
    getter database_history : Bool? = false

    @[YAML::Field(key: "media_spoilers")]
    getter media_spoilers : Bool? = false

    @[YAML::Field(key: "karma_reasons")]
    getter karma_reasons : Bool? = false

    @[YAML::Field(key: "regular_forwards")]
    getter regular_forwards : Bool? = false

    @[YAML::Field(key: "inactivity_limit")]
    getter inactivity_limit : Int32 = 0

    @[YAML::Field(key: "linked_network")]
    getter intermediary_linked_network : Hash(String, String) | String | Nil

    @[YAML::Field(ignore: true)]
    getter linked_network : Hash(String, String) = {} of String => String

    @[YAML::Field(key: "ranks")]
    property ranks : Hash(Int32, Rank) = {
      -10 => Rank.new(
        "Banned",
        Set.new([] of CommandPermissions),
        Set.new([] of MessagePermissions)
      ),
    }

    @[YAML::Field(key: "default_rank")]
    property default_rank : Int32 = 0

    @[YAML::Field(key: "karma_levels")]
    property karma_levels : Hash(Int32, String) = {} of Int32 => String

    @[YAML::Field(key: "toggle_r9k_text")]
    getter toggle_r9k_text : Bool? = false

    @[YAML::Field(key: "toggle_r9k_media")]
    getter toggle_r9k_media : Bool? = false

    @[YAML::Field(key: "toggle_r9k_forwards")]
    getter toggle_r9k_forwards : Bool? = false

    @[YAML::Field(key: "r9k_cooldown")]
    getter r9k_cooldown : Int32 = 0

    @[YAML::Field(key: "r9k_warn")]
    getter r9k_warn : Bool? = false

    @[YAML::Field(key: "valid_codepoints")]
    getter intermediate_valid_codepoints : Array(Array(Int32))?

    @[YAML::Field(ignore: true)]
    property valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)]

    # Command Toggles

    @[YAML::Field(key: "enable_start")]
    getter enable_start : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_stop")]
    getter enable_stop : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_info")]
    getter enable_info : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_users")]
    getter enable_users : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_version")]
    getter enable_version : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_toggle_karma")]
    getter enable_toggle_karma : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_toggle_debug")]
    getter enable_toggle_debug : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_reveal")]
    getter enable_reveal : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_tripcode")]
    getter enable_tripcode : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_sign")]
    getter enable_sign : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_tripsign")]
    getter enable_tripsign : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_karma_sign")]
    getter enable_karma_sign : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_ranksay")]
    getter enable_ranksay : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_motd")]
    getter enable_motd : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_help")]
    getter enable_help : Array(Bool) = [true, true]

    @[YAML::Field(key: "enable_upvotes")]
    getter enable_upvote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_downvotes")]
    getter enable_downvote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_promote")]
    getter enable_promote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_demote")]
    getter enable_demote : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_warn")]
    getter enable_warn : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_delete")]
    getter enable_delete : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_uncooldown")]
    getter enable_uncooldown : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_remove")]
    getter enable_remove : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_purge")]
    getter enable_purge : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_blacklist")]
    getter enable_blacklist : Array(Bool) = [true, false]

    @[YAML::Field(key: "enable_whitelist")]
    getter enable_whitelist : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_spoiler")]
    getter enable_spoiler : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_karma_info")]
    getter enable_karma_info : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_pin")]
    getter enable_pin : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_unpin")]
    getter enable_unpin : Array(Bool) = [false, false]

    @[YAML::Field(key: "enable_stats")]
    getter enable_stats : Array(Bool) = [false, false]

    # Relay Toggles

    @[YAML::Field(key: "relay_text")]
    getter relay_text : Bool? = true

    @[YAML::Field(key: "relay_animation")]
    getter relay_animation : Bool? = true

    @[YAML::Field(key: "relay_audio")]
    getter relay_audio : Bool? = true

    @[YAML::Field(key: "relay_document")]
    getter relay_document : Bool? = true

    @[YAML::Field(key: "relay_video")]
    getter relay_video : Bool? = true

    @[YAML::Field(key: "relay_video_note")]
    getter relay_video_note : Bool? = true

    @[YAML::Field(key: "relay_voice")]
    getter relay_voice : Bool? = true

    @[YAML::Field(key: "relay_photo")]
    getter relay_photo : Bool? = true

    @[YAML::Field(key: "relay_media_group")]
    getter relay_media_group : Bool? = true

    @[YAML::Field(key: "relay_poll")]
    getter relay_poll : Bool? = true

    @[YAML::Field(key: "relay_forwarded_message")]
    getter relay_forwarded_message : Bool? = true

    @[YAML::Field(key: "relay_sticker")]
    getter relay_sticker : Bool? = true

    @[YAML::Field(key: "relay_venue")]
    getter relay_venue : Bool? = false

    @[YAML::Field(key: "relay_location")]
    getter relay_location : Bool? = false

    @[YAML::Field(key: "relay_contact")]
    getter relay_contact : Bool? = false

    @[YAML::Field(key: "cooldown_base")]
    getter cooldown_base : Int32 = 5

    @[YAML::Field(key: "warn_lifespan")]
    getter warn_lifespan : Int32 = 7 * 24

    @[YAML::Field(key: "warn_deduction")]
    getter warn_deduction : Int32 = 10

    @[YAML::Field(key: "karma_economy")]
    getter karma_economy : KarmaHandler?

    @[YAML::Field(key: "spam_interval")]
    getter spam_interval : Int32 = 10

    @[YAML::Field(key: "spam_handler")]
    getter spam_handler : SpamHandler

    @[YAML::Field(key: "media_limit_period")]
    getter media_limit_period : Int32 = 0

    @[YAML::Field(key: "registration_open")]
    getter registration_open : Bool? = true

    @[YAML::Field(key: "pseudonymous")]
    getter pseudonymous : Bool? = false

    @[YAML::Field(key: "flag_signatures")]
    getter flag_signatures : Bool? = false

    @[YAML::Field(key: "statistics")]
    getter statistics : Bool? = false

    @[YAML::Field(key: "blacklist_contact")]
    getter blacklist_contact : String? = nil

    @[YAML::Field(key: "full_usercount")]
    getter full_usercount : Bool? = false

    @[YAML::Field(key: "sign_limit_interval")]
    getter sign_limit_interval : Int32 = 600

    @[YAML::Field(key: "upvote_limit_interval")]
    getter upvote_limit_interval : Int32 = 0

    @[YAML::Field(key: "downvote_limit_interval")]
    getter downvote_limit_interval : Int32 = 0

    @[YAML::Field(key: "smileys")]
    property smileys : Array(String) = [":)", ":|", ":/", ":("]

    @[YAML::Field(key: "strip_format")]
    property entities : Array(String) = ["bold", "italic", "text_link"]

    @[YAML::Field(key: "tripcode_salt")]
    getter salt : String = ""

    def self.parse_config : Config
      check_config(Config.from_yaml(File.open("config.yaml")))
    rescue ex : YAML::ParseException
      Log.error(exception: ex) { "Could not parse the given value at row #{ex.line_number}. This could be because a required value was not set or the wrong type was given." }
      exit
    rescue ex : File::NotFoundError | File::AccessDeniedError
      Log.error(exception: ex) { "Could not open \"./config.yaml\". Exiting..." }
      exit
    end

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

      unless config.karma_levels.empty? || (config.karma_levels.keys.sort! == config.karma_levels.keys)
        Log.notice { "Karma level keys were not in ascending order; defaulting to no karma levels." }
        config.karma_levels = {} of Int32 => String
      end

      set_log(config)
      config = check_and_init_ranks(config)
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

      config
    end

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
    # the YAML dictionary there into  `linked_network`
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
          Log.notice(exception: ex) { "Could not open linked network file, \"#{links}\"" }
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
