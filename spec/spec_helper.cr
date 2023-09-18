require "spec"
require "tourmaline"
require "../src/private-parlor-xt/**"
require "./database/*"
require "./mocks/*"

HISTORY_LIFESPAN = Time::Span.zero

module PrivateParlorXT
  def self.create_services(config : HandlerConfig? = nil, database : Database? = nil, history : History? = nil, ranks : Hash(Int32, String)? = nil, client : MockClient? = nil, spam : SpamHandler? = nil) : Services
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
      ranks = ranks = {
        1000 => Rank.new(
          "Host",
          Set{
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

    Services.new(
      config,
      Locale.parse_locale(Path["#{__DIR__}/../locales/"], "en-US"),
      database,
      history,
      AuthorizedRanks.new(ranks),
      Relay.new("", client || MockClient.new),
      spam,
    )
  end

  def self.generate_users(database : SQLiteDatabase)
    database.add_user(20000_i64, nil, "example", 1000)
    database.add_user(60200_i64, nil, "voorbeeld", 0)
    database.add_user(80300_i64, nil, "beispiel", 10)
    database.add_user(40000_i64, nil, "esimerkki", 0)
    database.add_user(70000_i64, nil, "BLACKLISTED", -10)

    user_one = SQLiteUser.new(20000_i64, "examp","example",1000,Time.utc(2023, 1, 2, 6),nil,Time.utc(2023, 7, 2, 6),nil,nil,0,nil,0,false,false,nil)
    user_two = SQLiteUser.new(60200_i64, "voorb","voorbeeld",0,Time.utc(2023, 1, 2, 6),nil,Time.utc(2023, 1, 2, 6),nil,nil,1,Time.utc(2023, 3, 2, 12),-10,false,false,nil)
    user_three = SQLiteUser.new(80300_i64, nil,"beispiel",10,Time.utc(2023, 1, 2, 6),nil,Time.utc(2023, 3, 2, 12),nil,nil,2,Time.utc(2023, 4, 2, 12),-20,false,true,nil)
    user_four = SQLiteUser.new(40000_i64, nil,"esimerkki",0,Time.utc(2023, 1, 2, 6),Time.utc(2023, 2, 4, 6),Time.utc(2023, 2, 4, 6),nil,nil,0,nil,0,false,false,nil)
    user_five = SQLiteUser.new(70000_i64, nil,"BLACKLISTED",-10,Time.utc(2023, 1, 2, 6),Time.utc(2023, 4, 2, 10),Time.utc(2023, 1, 2, 6),nil,nil,0,nil,0,false,false,nil)

    database.update_user(user_one)
    database.update_user(user_two)
    database.update_user(user_three)
    database.update_user(user_four)
    database.update_user(user_five)
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
    forward_date : Time? = nil, 
    reply_to_message : Tourmaline::Message? = nil,
    media_group_id : String? = nil,
    text : String? = nil,
    entities : Array(Tourmaline::MessageEntity) = [] of Tourmaline::MessageEntity,
    caption : String? = nil,
    animation : Tourmaline::Animation? = nil,
    audio : Tourmaline::Audio? = nil,
    document : Tourmaline::Document? = nil,
    photo : Array(Tourmaline::PhotoSize) = [] of Tourmaline::PhotoSize,
    video : Tourmaline::Video? = nil,
    video_note : Tourmaline::VideoNote? = nil,
    voice : Tourmaline::Voice? = nil,
    has_media_spoiler : Bool? = nil,
    contact : Tourmaline::Contact? = nil,
    poll : Tourmaline::Poll? = nil,
    venue : Tourmaline::Venue? = nil,
    location : Tourmaline::Location? = nil,
    ) : Tourmaline::Message
    Tourmaline::Message.new(
      message_id,
      Time.utc,
      Tourmaline::Chat.new(tourmaline_user.id, "private"),
      from: tourmaline_user,
      forward_date: forward_date,
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
      video: video,
      video_note: video_note,
      voice: voice,
      has_media_spoiler: has_media_spoiler,
      contact: contact,
      poll: poll,
      venue: venue,
      location: location,
    )
  end
end
