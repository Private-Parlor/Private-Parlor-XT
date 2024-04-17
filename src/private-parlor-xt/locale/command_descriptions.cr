require "yaml"

module PrivateParlorXT
  struct CommandDescriptions
    include YAML::Serializable

    @[YAML::Field(key: "start")]
    getter start : String

    @[YAML::Field(key: "stop")]
    getter stop : String

    @[YAML::Field(key: "info")]
    getter info : String

    @[YAML::Field(key: "users")]
    getter users : String

    @[YAML::Field(key: "version")]
    getter version : String

    @[YAML::Field(key: "upvote")]
    getter upvote : String

    @[YAML::Field(key: "downvote")]
    getter downvote : String

    @[YAML::Field(key: "toggle_karma")]
    getter toggle_karma : String

    @[YAML::Field(key: "toggle_debug")]
    getter toggle_debug : String

    @[YAML::Field(key: "reveal")]
    getter reveal : String

    @[YAML::Field(key: "tripcode")]
    getter tripcode : String

    @[YAML::Field(key: "promote")]
    getter promote : String

    @[YAML::Field(key: "demote")]
    getter demote : String

    @[YAML::Field(key: "sign")]
    getter sign : String

    @[YAML::Field(key: "tsign")]
    getter tsign : String

    @[YAML::Field(key: "ksign")]
    getter ksign : String

    @[YAML::Field(key: "ranksay")]
    getter ranksay : String

    @[YAML::Field(key: "warn")]
    getter warn : String

    @[YAML::Field(key: "delete")]
    getter delete : String

    @[YAML::Field(key: "uncooldown")]
    getter uncooldown : String

    @[YAML::Field(key: "remove")]
    getter remove : String

    @[YAML::Field(key: "purge")]
    getter purge : String

    @[YAML::Field(key: "spoiler")]
    getter spoiler : String

    @[YAML::Field(key: "karma_info")]
    getter karma_info : String

    @[YAML::Field(key: "pin")]
    getter pin : String

    @[YAML::Field(key: "unpin")]
    getter unpin : String

    @[YAML::Field(key: "stats")]
    getter stats : String

    @[YAML::Field(key: "blacklist")]
    getter blacklist : String

    @[YAML::Field(key: "unblacklist")]
    getter unblacklist : String

    @[YAML::Field(key: "whitelist")]
    getter whitelist : String

    @[YAML::Field(key: "motd")]
    getter motd : String

    @[YAML::Field(key: "help")]
    getter help : String

    @[YAML::Field(key: "motd_set")]
    getter motd_set : String

    @[YAML::Field(key: "ranked_info")]
    getter ranked_info : String
  end
end
