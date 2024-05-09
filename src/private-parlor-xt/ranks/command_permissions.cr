module PrivateParlorXT

  # Commands and command types which can be given to a `Rank` to permit using certain commands
  # 
  # ## Commands permitted for each type:
  # 
  # `Users`: View the exact number of joined, left, and blacklisted users
  # 
  # `Upvote`: Upvote messages
  # 
  # `Downvote`: Downvote messages
  # 
  # `Promote`: Promote users to the same rank AND/OR lower ranks (Mutually exclusive with `PromoteSame` and `PromoteLower`)
  # 
  # `PromoteLower`: Promote users to lower ranks ONLY (Mutually exclusive with `Promote` and `PromoteSame`)
  # 
  # `PromoteSame`: Promote users to the same rank ONLY (Mutually exclusive with `Promote` and `PromoteLower`)
  # 
  # `Demote`: Demote users of lower rank
  # 
  # `Sign`: Sign a message with the user's username
  # 
  # `TSign`: Sign a message with a tripcode
  # 
  # `Reveal`: Privately reveal username to another user
  # 
  # `Spoiler`: Add or remove a spoiler from a media message using `SpoilerCommand`
  # 
  # `Pin`: Pin a message to the chat
  # 
  # `Unpin`: Unpin the a message or the recent message
  # 
  # `Ranksay`: Sign a message with rank name (Mutually exclusive with `RanksayLower`)
  # 
  # `RanksayLower`: Sign a message with rank name OR name of a lower rank IF that rank can ranksay (Mutually exclusive with `Ranksay`)
  # 
  # `Warn`: Warn a message and give the user a cooldown
  # 
  # `Delete`: Delete a message and give the user a cooldown
  # 
  # `Uncooldown`: Remove a cooldown from a user
  # 
  # `Remove`: Delete message without giving the user a cooldown
  # 
  # `Purge`: Delete all messages from recently blacklisted users
  # 
  # `Blacklist`: Ban a user from the chat
  # 
  # `Whitelist`: Invite a user to the chat (Applicable only if registration is closed)
  # 
  # `MotdSet`: Modify and set the MOTD/rules
  # 
  # `RankedInfo`: Get info (OID, karma, cooldown duration) of a another user
  # 
  # `Unblacklist`: Unban a user from the chat
  enum CommandPermissions
    Users
    Upvote
    Downvote
    Promote
    PromoteLower
    PromoteSame
    Demote
    Sign
    TSign
    Reveal
    Spoiler
    Pin
    Unpin
    Ranksay
    RanksayLower
    Warn
    Delete
    Uncooldown
    Remove
    Purge
    Blacklist
    Whitelist
    MotdSet
    RankedInfo
    Unblacklist
  end
end
