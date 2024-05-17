module PrivateParlorXT
  # Message types which can be given to a `Rank` to permit sending messages of that type
  #
  # ## Messages permitted for each type:
  #
  # `Text`: Text messages without any media
  #
  # `Animation`: GIFs
  #
  # `Audio`: Audio files/messages
  #
  # `Document`: General files
  #
  # `Video`: Videos
  #
  # `VideoNote`: Round video/voice messages
  #
  # `Voice`: Voice messages
  #
  # `Photo`: Photos
  #
  # `MediaGroup`: Albums of any kind
  #
  # `Poll`: Polls
  #
  # `Forward`: Forwarded messages
  #
  # `Sticker`:Stickers
  #
  # `Venue`: Venues
  #
  # `Location`: Locations
  #
  # `Contact`: SMS contacts
  enum MessagePermissions
    Text
    Animation
    Audio
    Document
    Video
    VideoNote
    Voice
    Photo
    MediaGroup
    Poll
    Forward
    Sticker
    Venue
    Location
    Contact
  end
end
