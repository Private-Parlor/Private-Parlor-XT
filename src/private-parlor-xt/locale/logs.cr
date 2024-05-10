require "yaml"

module PrivateParlorXT

  # A container for various log messages
  struct Logs
    include YAML::Serializable

    @[YAML::Field(key: "start")]
    # When the bot starts
    getter start : String

    @[YAML::Field(key: "joined")]
    # When a user joins the chat
    getter joined : String

    @[YAML::Field(key: "rejoined")]
    # When a user rejoins the chat
    getter rejoined : String

    @[YAML::Field(key: "left")]
    # When a user leaves the chat
    getter left : String

    @[YAML::Field(key: "promoted")]
    # When a user has been promoted
    getter promoted : String

    @[YAML::Field(key: "demoted")]
    # When a user has been demoted
    getter demoted : String

    @[YAML::Field(key: "warned")]
    # When a user has been given a warning
    getter warned : String

    @[YAML::Field(key: "message_deleted")]
    # When a message gets deleted and a user is given a cooldown
    getter message_deleted : String

    @[YAML::Field(key: "message_removed")]
    # When a message gets removed
    getter message_removed : String

    @[YAML::Field(key: "removed_cooldown")]
    # When a user's cooldown gets manually removed
    getter removed_cooldown : String

    @[YAML::Field(key: "blacklisted")]
    # When a user gets blacklisted
    getter blacklisted : String

    @[YAML::Field(key: "unblacklisted")]
    # When a user gets unbanned
    getter unblacklisted : String

    @[YAML::Field(key: "whitelisted")]
    # When a user is permitted to join the chat
    getter whitelisted : String

    @[YAML::Field(key: "reason_prefix")]
    # Format for the reason found in warn, delete, and blacklist replies
    getter reason_prefix : String

    @[YAML::Field(key: "spoiled")]
    # When a spoiler is given a to a message's media
    getter spoiled : String

    @[YAML::Field(key: "unspoiled")]
    # When a media spoiler is removed from a message
    getter unspoiled : String

    @[YAML::Field(key: "upvoted")]
    # When a user gets upvoted with a reason
    getter upvoted : String

    @[YAML::Field(key: "downvoted")]
    # When a user gets downvoted with a reason
    getter downvoted : String

    @[YAML::Field(key: "revealed")]
    # When a user privately reveals his username to another user
    getter revealed : String

    @[YAML::Field(key: "pinned")]
    # When a message gets pinned to the chat
    getter pinned : String

    @[YAML::Field(key: "unpinned")]
    # When a message gets unpinned from the chat
    getter unpinned : String

    @[YAML::Field(key: "unpinned_recent")]
    # When the most recently pinned message gets unpinned
    getter unpinned_recent : String

    @[YAML::Field(key: "motd_set")]
    # When the motd gets reset
    getter motd_set : String

    @[YAML::Field(key: "ranked_message")]
    # When a ranked user sends a message signed with his rank
    getter ranked_message : String

    @[YAML::Field(key: "force_leave")]
    # When a user forcefully removed from the bot due to having blocked it
    getter force_leave : String
  end
end
