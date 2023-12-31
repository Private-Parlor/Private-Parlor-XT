require "yaml"

module PrivateParlorXT
  struct Logs
    include YAML::Serializable

    @[YAML::Field(key: "start")]
    getter start : String

    @[YAML::Field(key: "joined")]
    getter joined : String

    @[YAML::Field(key: "rejoined")]
    getter rejoined : String

    @[YAML::Field(key: "left")]
    getter left : String

    @[YAML::Field(key: "promoted")]
    getter promoted : String

    @[YAML::Field(key: "demoted")]
    getter demoted : String

    @[YAML::Field(key: "warned")]
    getter warned : String

    @[YAML::Field(key: "message_deleted")]
    getter message_deleted : String

    @[YAML::Field(key: "message_removed")]
    getter message_removed : String

    @[YAML::Field(key: "removed_cooldown")]
    getter removed_cooldown : String

    @[YAML::Field(key: "blacklisted")]
    getter blacklisted : String

    @[YAML::Field(key: "whitelisted")]
    getter whitelisted : String

    @[YAML::Field(key: "reason_prefix")]
    getter reason_prefix : String

    @[YAML::Field(key: "spoiled")]
    getter spoiled : String

    @[YAML::Field(key: "unspoiled")]
    getter unspoiled : String

    @[YAML::Field(key: "upvoted")]
    getter upvoted : String

    @[YAML::Field(key: "downvoted")]
    getter downvoted : String

    @[YAML::Field(key: "revealed")]
    getter revealed : String

    @[YAML::Field(key: "pinned")]
    getter pinned : String

    @[YAML::Field(key: "unpinned")]
    getter unpinned : String

    @[YAML::Field(key: "unpinned_recent")]
    getter unpinned_recent : String

    @[YAML::Field(key: "motd_set")]
    getter motd_set : String

    @[YAML::Field(key: "ranked_message")]
    getter ranked_message : String

    @[YAML::Field(key: "force_leave")]
    getter force_leave : String
  end
end
