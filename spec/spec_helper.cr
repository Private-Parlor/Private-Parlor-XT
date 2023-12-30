require "spec"
require "tourmaline"
require "../src/private-parlor-xt/**"
require "./database/*"
require "./mocks/*"

HISTORY_LIFESPAN = Time::Span.zero

module PrivateParlorXT
  def self.create_services(
    config : HandlerConfig? = nil,
    database : Database? = nil,
    history : History? = nil,
    ranks : Hash(Int32, Rank)? = nil,
    relay : Relay? = nil,
    client : MockClient? = nil,
    spam : SpamHandler? = nil,
    r9k : Robot9000? = nil
  ) : Services
    unless config
      config = HandlerConfig.new(MockConfig.new)
    end

    unless database
      database = SQLiteDatabase.new(DB.open("sqlite3://%3Amemory%3A"))
    end

    unless history
      history = CachedHistory.new(HISTORY_LIFESPAN)
    end

    unless ranks
      ranks = {
        1000 => Rank.new(
          "Host",
          Set{
            CommandPermissions::Purge,
            CommandPermissions::Promote,
            CommandPermissions::Demote,
            CommandPermissions::RanksayLower,
            CommandPermissions::Upvote,
            CommandPermissions::Downvote,
          },
          Set{
            MessagePermissions::Text,
            MessagePermissions::Photo,
          },
        ),
        100 => Rank.new(
          "Admin",
          Set{
            CommandPermissions::PromoteLower,
            CommandPermissions::Demote,
            CommandPermissions::RanksayLower,
            CommandPermissions::Upvote,
            CommandPermissions::Downvote,
          },
          Set{
            MessagePermissions::Text,
            MessagePermissions::Photo,
          },
        ),
        10 => Rank.new(
          "Mod",
          Set{
            CommandPermissions::PromoteSame,
            CommandPermissions::Ranksay,
            CommandPermissions::Upvote,
            CommandPermissions::Downvote,
          },
          Set{
            MessagePermissions::Text,
            MessagePermissions::Photo,
          },
        ),
        0 => Rank.new(
          "User",
          Set{
            CommandPermissions::TSign,
            CommandPermissions::Upvote,
            CommandPermissions::Downvote,
          },
          Set{
            MessagePermissions::Text,
          },
        ),
        -10 => Rank.new(
          "Blacklisted",
          Set(CommandPermissions).new,
          Set(MessagePermissions).new,
        ),
      }
    end

    unless relay
      relay = Relay.new("", client || MockClient.new)
    end

    localization = Localization.parse_locale(Path["#{__DIR__}/../locales/"], "en-US")

    Services.new(
      config,
      localization.locale,
      localization.replies,
      localization.logs,
      localization.command_descriptions,
      database,
      history,
      AuthorizedRanks.new(ranks),
      relay,
      spam,
      r9k,
    )
  end

  def self.generate_users(database : Database)
    database.add_user(20000_i64, nil, "example", 1000)
    database.update_user(MockUser.new(
      id: 20000_i64,
      username: "examp",
      realname: "example",
      rank: 1000,
      joined: Time.utc(2023, 1, 2, 6),
      left: nil,
      last_active: Time.utc(2023, 7, 2, 6),
      cooldown_until: nil,
      blacklist_reason: nil,
      warnings: 0,
      warn_expiry: nil,
      karma: 0,
      hide_karma: false,
      debug_enabled: false,
      tripcode: nil
    ))

    database.add_user(60200_i64, nil, "voorbeeld", 0)
    database.update_user(MockUser.new(
      id: 60200_i64,
      username: "voorb",
      realname: "voorbeeld",
      rank: 0,
      joined: Time.utc(2023, 1, 2, 6),
      left: nil,
      last_active: Time.utc(2023, 1, 2, 6),
      cooldown_until: nil,
      blacklist_reason: nil,
      warnings: 1,
      warn_expiry: Time.utc(2023, 3, 2, 12),
      karma: -10,
      hide_karma: false,
      debug_enabled: false,
      tripcode: "Voorb#SecurePassword"
    ))

    database.add_user(80300_i64, nil, "beispiel", 10)
    database.update_user(MockUser.new(
      id: 80300_i64,
      username: nil,
      realname: "beispiel",
      rank: 10,
      joined: Time.utc(2023, 1, 2, 6),
      left: nil,
      last_active: Time.utc(2023, 3, 2, 12),
      cooldown_until: nil,
      blacklist_reason: nil,
      warnings: 2,
      warn_expiry: Time.utc(2023, 4, 2, 12),
      karma: -20,
      hide_karma: false,
      debug_enabled: true,
      tripcode: nil
    ))

    database.add_user(40000_i64, nil, "esimerkki", 0)
    database.update_user(MockUser.new(
      id: 40000_i64,
      username: nil,
      realname: "esimerkki",
      rank: 0,
      joined: Time.utc(2023, 1, 2, 6),
      left: Time.utc(2023, 2, 4, 6),
      last_active: Time.utc(2023, 2, 4, 6),
      cooldown_until: nil,
      blacklist_reason: nil,
      warnings: 0,
      warn_expiry: nil,
      karma: 0,
      hide_karma: false,
      debug_enabled: false,
      tripcode: nil
    ))

    database.add_user(70000_i64, nil, "BLACKLISTED", -10)
    database.update_user(MockUser.new(
      id: 70000_i64,
      username: nil,
      realname: "BLACKLISTED",
      rank: -10,
      joined: Time.utc(2023, 1, 2, 6),
      left: Time.utc(2023, 4, 2, 10),
      last_active: Time.utc(2023, 1, 2, 6),
      cooldown_until: nil,
      blacklist_reason: nil,
      warnings: 0,
      warn_expiry: nil,
      karma: 0,
      hide_karma: false,
      debug_enabled: false,
      tripcode: nil
    ))

    database.add_user(50000_i64, nil, "cooldown", 0)
    database.update_user(MockUser.new(
      id: 50000_i64,
      username: nil,
      realname: "cooldown",
      rank: 0,
      joined: Time.utc(2023, 1, 2, 6),
      left: nil,
      last_active: Time.utc(2023, 2, 4, 6),
      cooldown_until: Time.utc(2033, 2, 4, 6),
      blacklist_reason: nil,
      warnings: 0,
      warn_expiry: nil,
      karma: 0,
      hide_karma: false,
      debug_enabled: false,
      tripcode: nil
    ))
  end

  def self.generate_history(history : History)
    history.new_message(80300, 1)
    history.new_message(20000, 4)
    history.new_message(60200, 8)

    history.add_to_history(1, 2, 60200)
    history.add_to_history(1, 3, 20000)

    history.add_to_history(4, 5, 20000)
    history.add_to_history(4, 6, 80300)
    history.add_to_history(4, 7, 60200)

    history.add_to_history(8, 9, 20000)
    history.add_to_history(8, 10, 80300)

    history.add_rating(2, 60200)
  end

  def self.create_context(client : MockClient, update : Tourmaline::Update) : Tourmaline::Context
    Tourmaline::Context.new(client, update)
  end

  def self.create_update(update_id : Int32 | Int64, message : Tourmaline::Message? = nil) : Tourmaline::Update
    Tourmaline::Update.new(update_id, message)
  end

  def self.create_message(
    message_id : Int64,
    tourmaline_user : Tourmaline::User,
    reply_to_message : Tourmaline::Message? = nil,
    media_group_id : String? = nil,
    text : String? = nil,
    entities : Array(Tourmaline::MessageEntity) = [] of Tourmaline::MessageEntity,
    caption : String? = nil,
    animation : Tourmaline::Animation? = nil,
    audio : Tourmaline::Audio? = nil,
    document : Tourmaline::Document? = nil,
    photo : Array(Tourmaline::PhotoSize) = [] of Tourmaline::PhotoSize,
    sticker : Tourmaline::Sticker? = nil,
    video : Tourmaline::Video? = nil,
    video_note : Tourmaline::VideoNote? = nil,
    voice : Tourmaline::Voice? = nil,
    has_media_spoiler : Bool? = nil,
    contact : Tourmaline::Contact? = nil,
    poll : Tourmaline::Poll? = nil,
    venue : Tourmaline::Venue? = nil,
    location : Tourmaline::Location? = nil,
    forward_origin : Tourmaline::MessageOrigin? = nil,
    preformatted : Bool? = nil
  ) : Tourmaline::Message
    message = Tourmaline::Message.new(
      message_id,
      Time.utc,
      Tourmaline::Chat.new(tourmaline_user.id, "private"),
      from: tourmaline_user,
      reply_to_message: reply_to_message,
      media_group_id: media_group_id,
      text: text,
      entities: entities,
      caption: caption,
      caption_entities: entities,
      animation: animation,
      audio: audio,
      document: document,
      photo: photo,
      sticker: sticker,
      video: video,
      video_note: video_note,
      voice: voice,
      has_media_spoiler: has_media_spoiler,
      contact: contact,
      poll: poll,
      venue: venue,
      location: location,
      forward_origin: forward_origin,
    )

    message.preformatted = preformatted

    message
  end
end
