require "yaml"

module PrivateParlorXT

  # A container for various system message replies
  struct Replies
    include YAML::Serializable

    @[YAML::Field(key: "joined")]
    # Sent when the user has joined the chat
    getter joined : String

    @[YAML::Field(key: "joined_pseudonym")]
    # Sent when the user has joined the chat, and prompts the user to set a tripcode
    getter joined_pseudonym : String

    @[YAML::Field(key: "rejoined")]
    # When the user rejoins the chat after having left
    getter rejoined : String

    @[YAML::Field(key: "left")]
    # When the user leaves the chat
    getter left : String

    @[YAML::Field(key: "already_in_chat")]
    # When the user attempts to join, but has not left and is still in the chat
    getter already_in_chat : String

    @[YAML::Field(key: "registration_closed")]
    # When the user attempts to join but cannot due to registrations being closed
    getter registration_closed : String

    @[YAML::Field(key: "added_to_chat")]
    # When the user is whitelisted
    getter added_to_chat : String

    @[YAML::Field(key: "already_whitelisted")]
    # When the invoker attempts to whitelist a user who is already in the chat
    getter already_whitelisted : String

    @[YAML::Field(key: "not_in_chat")]
    # When the user attempts to chat, but cannot as he hasn't joined the chat
    getter not_in_chat : String

    @[YAML::Field(key: "not_in_cooldown")]
    # When the invoker attempts to remove a cooldown from a user who is not cooldowned
    getter not_in_cooldown : String

    @[YAML::Field(key: "rejected_message")]
    # When the user sends a message that has invalid characters in the text
    getter rejected_message : String

    @[YAML::Field(key: "deanon_poll")]
    # When the user attempts to send a poll that does not have anonymous voting
    getter deanon_poll : String

    @[YAML::Field(key: "missing_args")]
    # When the invoker uses a command without the required arguments
    getter missing_args : String

    @[YAML::Field(key: "command_disabled")]
    # When the invoker attempts to us a command that is disabled
    getter command_disabled : String

    @[YAML::Field(key: "media_disabled")]
    # When the user attempts to send a message type that is disabled
    getter media_disabled : String

    @[YAML::Field(key: "no_reply")]
    # When the invoker uses a command that requires a reply but does not reply to a message
    getter no_reply : String

    @[YAML::Field(key: "not_in_cache")]
    # When the user attempts ot reply to a message that is not in the message `History` anymore
    getter not_in_cache : String

    @[YAML::Field(key: "no_tripcode_set")]
    # When the user attempts to sign with a tripcode without having set a tripcode
    getter no_tripcode_set : String

    @[YAML::Field(key: "no_user_found")]
    # When the user searched for could not be found from the given name
    getter no_user_found : String

    @[YAML::Field(key: "no_user_oid_found")]
    # When the user searched for could not be found from the given OID
    getter no_user_oid_found : String

    @[YAML::Field(key: "no_rank_found")]
    # When the rank searched for could not be found from the given name
    getter no_rank_found : String

    @[YAML::Field(key: "promoted")]
    # When the user has been promoted to a new rank
    getter promoted : String

    @[YAML::Field(key: "help_header")]
    # The header displayed at the top of every `HelpCommand` reply
    getter help_header : String

    @[YAML::Field(key: "help_rank_commands")]
    # Header shown in the `HelpCommand` reply containing the name of the user's `Rank`
    getter help_rank_commands : String

    @[YAML::Field(key: "help_reply_commands")]
    # Header in the `HelpCommand` below which contains the commands that require a reply
    getter help_reply_commands : String

    @[YAML::Field(key: "toggle_karma")]
    # Message shown when the user enables or disables karma notifications
    getter toggle_karma : String

    @[YAML::Field(key: "toggle_debug")]
    # Message shown when the user enables or disables debug mode
    getter toggle_debug : String

    @[YAML::Field(key: "karma_reason")]
    # The formatting for a karma reason
    getter karma_reason : String

    @[YAML::Field(key: "gave_upvote")]
    # When the user gives an upvote
    getter gave_upvote : String

    @[YAML::Field(key: "got_upvote")]
    # When the user receives an upvote
    getter got_upvote : String

    @[YAML::Field(key: "upvoted_own_message")]
    # When the user attempts to upvote his own message
    getter upvoted_own_message : String

    @[YAML::Field(key: "already_voted")]
    # When the user attempts to upvote/downvote a message he already upvoted or downvoted
    getter already_voted : String

    @[YAML::Field(key: "gave_downvote")]
    # When the user gives a downvote
    getter gave_downvote : String

    @[YAML::Field(key: "got_downvote")]
    # When the user receives a downvote
    getter got_downvote : String

    @[YAML::Field(key: "downvoted_own_message")]
    # When the user attempts to downvote his own message
    getter downvoted_own_message : String

    @[YAML::Field(key: "karma_info")]
    # Message containing information about the user's karma and karma level progress
    getter karma_info : String

    @[YAML::Field(key: "karma_level_up")]
    # When the user gains a karma level
    getter karma_level_up : String

    @[YAML::Field(key: "karma_level_down")]
    # When the user loses a karma level
    getter karma_level_down : String

    @[YAML::Field(key: "insufficient_karma")]
    # When the user has insufficient karma to send a message when using the `KarmaHandler`
    getter insufficient_karma : String

    @[YAML::Field(key: "already_warned")]
    # When the invoker attempts to warn a message with `WarnCommand` that was already warned
    getter already_warned : String

    @[YAML::Field(key: "private_sign")]
    # When the user cannot sign his message due to having forward privacy enabled
    getter private_sign : String

    @[YAML::Field(key: "username_reveal")]
    # Message privately sent to a user when another user reveal's his username
    getter username_reveal : String

    @[YAML::Field(key: "spamming")]
    # When the user is spamming and cannot chat at this time
    getter spamming : String

    @[YAML::Field(key: "sign_spam")]
    # When the user is signing messages too often
    getter sign_spam : String

    @[YAML::Field(key: "upvote_spam")]
    # When the user is upvoting too often
    getter upvote_spam : String

    @[YAML::Field(key: "downvote_spam")]
    # When the user is downvoting too often
    getter downvote_spam : String

    @[YAML::Field(key: "tripcode_format")]
    # Message containing the format for setting tripcodes
    getter tripcode_format : String

    @[YAML::Field(key: "flag_sign_format")]
    # Message containing the format for setting flag signs
    getter flag_sign_format : String

    @[YAML::Field(key: "invalid_tripcode_format")]
    # When the user attempts to set a tripcode with the wrong format
    getter invalid_tripcode_format : String

    @[YAML::Field(key: "tripcode_set_format")]
    # The layout for tripcode headers
    getter tripcode_set_format : String

    @[YAML::Field(key: "flag_sign_set_format")]
    # The layout for flat sign headers
    getter flag_sign_set_format : String

    @[YAML::Field(key: "tripcode_set")]
    # Message containing the set tripcode and how it will be displayed
    getter tripcode_set : String

    @[YAML::Field(key: "tripcode_info")]
    # Message containing the user's current tripcode
    getter tripcode_info : String

    @[YAML::Field(key: "tripcode_unset")]
    # Message telling the user that his tripcode is not set
    getter tripcode_unset : String

    @[YAML::Field(key: "user_info")]
    # Message containing information about the user
    getter user_info : String

    @[YAML::Field(key: "info_warning")]
    # Format for `user_info` when the user has a warning
    getter info_warning : String

    @[YAML::Field(key: "ranked_info")]
    # Message containing information about another user
    getter ranked_info : String

    @[YAML::Field(key: "cooldown_true")]
    # Format for `user_info` when the user is cooldowned
    getter cooldown_true : String

    @[YAML::Field(key: "cooldown_false")]
    # Format for `user_info` when the user is not cooldowned
    getter cooldown_false : String

    @[YAML::Field(key: "user_count")]
    # Message containing the total number of users
    getter user_count : String

    @[YAML::Field(key: "user_count_full")]
    # Message containing the total number of joined, left, and blacklisted users
    getter user_count_full : String

    @[YAML::Field(key: "message_deleted")]
    # When one of the user's messages was deleted
    getter message_deleted : String

    @[YAML::Field(key: "message_removed")]
    # When one of the user's messages was removed
    getter message_removed : String

    @[YAML::Field(key: "reason_prefix")]
    # Format for the reason found in warn, delete, and blacklist replies
    getter reason_prefix : String

    @[YAML::Field(key: "cooldown_given")]
    # When the user is given a cooldown
    getter cooldown_given : String

    @[YAML::Field(key: "on_cooldown")]
    # When the user is on cooldown and cannot speak at this time
    getter on_cooldown : String

    @[YAML::Field(key: "unoriginal_message")]
    # When the user sends an unorginal message when `Robot9000` is enabled
    getter unoriginal_message : String

    @[YAML::Field(key: "r9k_cooldown")]
    # When the user sends an unoriginal message and is cooldowned when `Robot9000` is enabled
    getter r9k_cooldown : String

    @[YAML::Field(key: "media_limit")]
    # When the user cannot chat right now due to being too new when the media limit is enabled
    getter media_limit : String

    @[YAML::Field(key: "blacklisted")]
    # When the user has been blacklisted
    getter blacklisted : String

    @[YAML::Field(key: "blacklist_contact")]
    # Format for the contact in `blacklisted` replies
    getter blacklist_contact : String

    @[YAML::Field(key: "unblacklisted")]
    # When the user has been unbanned
    getter unblacklisted : String

    @[YAML::Field(key: "purge_complete")]
    # Message returned after invoking `PurgeCommand`
    getter purge_complete : String

    @[YAML::Field(key: "inactive")]
    # When the user has been kicked due to inactivity
    getter inactive : String

    @[YAML::Field(key: "config_stats")]
    # Message containing general bot information when `Statistics` are enabled
    getter config_stats : String

    @[YAML::Field(key: "message_stats")]
    # Message containing totals of different message types when `Statistics` are enabled
    getter message_stats : String

    @[YAML::Field(key: "full_user_stats")]
    # Message containing totals of joined, left, and blacklisted users when `Statistics` are enabled
    getter full_user_stats : String

    @[YAML::Field(key: "user_stats")]
    # Message containing user totals when `Statistics` are enabled
    getter user_stats : String

    @[YAML::Field(key: "karma_stats")]
    # Message containing totals of upvotes and downvotes when `Statistics` are enabled
    getter karma_stats : String

    @[YAML::Field(key: "karma_level_stats")]
    # Message containing totals for each karma level when `Statistics` are enabled 
    getter karma_level_stats : String

    @[YAML::Field(key: "robot9000_stats")]
    # Message containing totals for unique and unoriginal messages when `Statistics` are enabled
    getter robot9000_stats : String

    @[YAML::Field(key: "no_stats_available")]
    # When there are no `Statistics` available
    getter no_stats_available : String

    @[YAML::Field(key: "success")]
    # When the command executed successfully
    getter success : String

    @[YAML::Field(key: "fail")]
    # When the command fails
    getter fail : String
  end
end
