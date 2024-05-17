require "yaml"

module PrivateParlorXT
  # A container for various command descriptions
  class CommandDescriptions
    include YAML::Serializable

    @[YAML::Field(key: "start")]
    # Description for the `StartCommand`
    getter start : String

    @[YAML::Field(key: "stop")]
    # Description for the `StopCommand`
    getter stop : String

    @[YAML::Field(key: "info")]
    # Description for the `InfoCommand`
    getter info : String

    @[YAML::Field(key: "users")]
    # Description for the `UsersCommand`
    getter users : String

    @[YAML::Field(key: "version")]
    # Description for the `VersionCommand`
    getter version : String

    @[YAML::Field(key: "upvote")]
    # Description for the `UpvoteHandler`
    getter upvote : String

    @[YAML::Field(key: "downvote")]
    # Description for the `DownvoteHandler`
    getter downvote : String

    @[YAML::Field(key: "toggle_karma")]
    # Description for the `ToggleKarmaCommand`
    getter toggle_karma : String

    @[YAML::Field(key: "toggle_debug")]
    # Description for the `ToggleDebugCommand`
    getter toggle_debug : String

    @[YAML::Field(key: "reveal")]
    # Description for the `RevealCommand`
    getter reveal : String

    @[YAML::Field(key: "tripcode")]
    # Description for the `TripcodeCommand`
    getter tripcode : String

    @[YAML::Field(key: "promote")]
    # Description for the `PromoteCommand`
    getter promote : String

    @[YAML::Field(key: "demote")]
    # Description for the `DemoteCommand`
    getter demote : String

    @[YAML::Field(key: "sign")]
    # Description for the `SignCommand`
    getter sign : String

    @[YAML::Field(key: "tsign")]
    # Description for the `TripcodeSignCommand`
    getter tsign : String

    @[YAML::Field(key: "ksign")]
    # Description for the `KarmaSignCommand`
    getter ksign : String

    @[YAML::Field(key: "ranksay")]
    # Description for the `RanksayCommand`
    getter ranksay : String

    @[YAML::Field(key: "warn")]
    # Description for the `WarnCommand`
    getter warn : String

    @[YAML::Field(key: "delete")]
    # Description for the `DeleteCommand`
    getter delete : String

    @[YAML::Field(key: "uncooldown")]
    # Description for the `UncooldownCommand`
    getter uncooldown : String

    @[YAML::Field(key: "remove")]
    # Description for the `RemoveCommand`
    getter remove : String

    @[YAML::Field(key: "purge")]
    # Description for the `PurgeCommand`
    getter purge : String

    @[YAML::Field(key: "spoiler")]
    # Description for the `SpoilerCommand`
    getter spoiler : String

    @[YAML::Field(key: "karma_info")]
    # Description for the `KarmaInfoCommand`
    getter karma_info : String

    @[YAML::Field(key: "pin")]
    # Description for the `PinCommand`
    getter pin : String

    @[YAML::Field(key: "unpin")]
    # Description for the `UnpinCommand`
    getter unpin : String

    @[YAML::Field(key: "stats")]
    # Description for the `StatsCommand`
    getter stats : String

    @[YAML::Field(key: "blacklist")]
    # Description for the `BlacklistCommand`
    getter blacklist : String

    @[YAML::Field(key: "unblacklist")]
    # Description for the `UnblacklistCommand`
    getter unblacklist : String

    @[YAML::Field(key: "whitelist")]
    # Description for the `WhitelistCommand`
    getter whitelist : String

    @[YAML::Field(key: "motd")]
    # Description for the `MotdCommand`
    getter motd : String

    @[YAML::Field(key: "help")]
    # Description for the `HelpCommand`
    getter help : String

    @[YAML::Field(key: "motd_set")]
    # Description for the `MotdCommand` when a new MOTD is set
    getter motd_set : String

    @[YAML::Field(key: "ranked_info")]
    # Description for the `InfoCommand` when optaining information about another user
    getter ranked_info : String
  end
end
