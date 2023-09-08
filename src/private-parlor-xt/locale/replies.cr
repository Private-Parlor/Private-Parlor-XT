require "yaml"

module PrivateParlorXT
  class Replies
    include YAML::Serializable

    @[YAML::Field(key: "joined")]
    getter joined : String

    @[YAML::Field(key: "joined_pseudonym")]
    getter joined_pseudonym : String

    @[YAML::Field(key: "rejoined")]
    getter rejoined : String

    @[YAML::Field(key: "left")]
    getter left : String

    @[YAML::Field(key: "already_in_chat")]
    getter already_in_chat : String

    @[YAML::Field(key: "registration_closed")]
    getter registration_closed : String

    @[YAML::Field(key: "added_to_chat")]
    getter added_to_chat : String

    @[YAML::Field(key: "already_whitelisted")]
    getter already_whitelisted : String

    @[YAML::Field(key: "not_in_chat")]
    getter not_in_chat : String

    @[YAML::Field(key: "not_in_cooldown")]
    getter not_in_cooldown : String

    @[YAML::Field(key: "rejected_message")]
    getter rejected_message : String

    @[YAML::Field(key: "deanon_poll")]
    getter deanon_poll : String

    @[YAML::Field(key: "missing_args")]
    getter missing_args : String

    @[YAML::Field(key: "command_disabled")]
    getter command_disabled : String

    @[YAML::Field(key: "media_disabled")]
    getter media_disabled : String

    @[YAML::Field(key: "no_reply")]
    getter no_reply : String

    @[YAML::Field(key: "not_in_cache")]
    getter not_in_cache : String

    @[YAML::Field(key: "no_tripcode_set")]
    getter no_tripcode_set : String

    @[YAML::Field(key: "no_user_found")]
    getter no_user_found : String

    @[YAML::Field(key: "no_user_oid_found")]
    getter no_user_oid_found : String

    @[YAML::Field(key: "no_rank_found")]
    getter no_rank_found : String

    @[YAML::Field(key: "promoted")]
    getter promoted : String

    @[YAML::Field(key: "help_header")]
    getter help_header : String

    @[YAML::Field(key: "help_rank_commands")]
    getter help_rank_commands : String

    @[YAML::Field(key: "help_reply_commands")]
    getter help_reply_commands : String

    @[YAML::Field(key: "toggle_karma")]
    getter toggle_karma : String

    @[YAML::Field(key: "toggle_debug")]
    getter toggle_debug : String

    @[YAML::Field(key: "gave_upvote")]
    getter gave_upvote : String

    @[YAML::Field(key: "got_upvote")]
    getter got_upvote : String

    @[YAML::Field(key: "upvoted_own_message")]
    getter upvoted_own_message : String

    @[YAML::Field(key: "already_voted")]
    getter already_voted : String

    @[YAML::Field(key: "gave_downvote")]
    getter gave_downvote : String

    @[YAML::Field(key: "got_downvote")]
    getter got_downvote : String

    @[YAML::Field(key: "downvoted_own_message")]
    getter downvoted_own_message : String

    @[YAML::Field(key: "karma_info")]
    getter karma_info : String

    @[YAML::Field(key: "already_warned")]
    getter already_warned : String

    @[YAML::Field(key: "private_sign")]
    getter private_sign : String

    @[YAML::Field(key: "username_reveal")]
    getter username_reveal : String

    @[YAML::Field(key: "spamming")]
    getter spamming : String

    @[YAML::Field(key: "sign_spam")]
    getter sign_spam : String

    @[YAML::Field(key: "upvote_spam")]
    getter upvote_spam : String

    @[YAML::Field(key: "downvote_spam")]
    getter downvote_spam : String

    @[YAML::Field(key: "invalid_tripcode_format")]
    getter invalid_tripcode_format : String

    @[YAML::Field(key: "tripcode_set")]
    getter tripcode_set : String

    @[YAML::Field(key: "tripcode_info")]
    getter tripcode_info : String

    @[YAML::Field(key: "tripcode_unset")]
    getter tripcode_unset : String

    @[YAML::Field(key: "user_info")]
    getter user_info : String

    @[YAML::Field(key: "info_warning")]
    getter info_warning : String

    @[YAML::Field(key: "ranked_info")]
    getter ranked_info : String

    @[YAML::Field(key: "cooldown_true")]
    getter cooldown_true : String

    @[YAML::Field(key: "cooldown_false")]
    getter cooldown_false : String

    @[YAML::Field(key: "user_count")]
    getter user_count : String

    @[YAML::Field(key: "user_count_full")]
    getter user_count_full : String

    @[YAML::Field(key: "message_deleted")]
    getter message_deleted : String

    @[YAML::Field(key: "message_removed")]
    getter message_removed : String

    @[YAML::Field(key: "reason_prefix")]
    getter reason_prefix : String

    @[YAML::Field(key: "cooldown_given")]
    getter cooldown_given : String

    @[YAML::Field(key: "on_cooldown")]
    getter on_cooldown : String

    @[YAML::Field(key: "unoriginal_message")]
    getter unoriginal_message : String

    @[YAML::Field(key: "r9k_cooldown")]
    getter r9k_cooldown : String

    @[YAML::Field(key: "media_limit")]
    getter media_limit : String

    @[YAML::Field(key: "blacklisted")]
    getter blacklisted : String

    @[YAML::Field(key: "blacklist_contact")]
    getter blacklist_contact : String

    @[YAML::Field(key: "purge_complete")]
    getter purge_complete : String

    @[YAML::Field(key: "inactive")]
    getter inactive : String

    @[YAML::Field(key: "success")]
    getter success : String

    @[YAML::Field(key: "fail")]
    getter fail : String
  end
end
