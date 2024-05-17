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
    spam : SpamHandler? = nil,
    r9k : Robot9000? = nil,
    karma_economy : KarmaHandler? = nil,
    statistics : Statistics? = nil
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

    relay = MockRelay.new("", MockClient.new)

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
      karma_economy,
      statistics,
    )
  end

  def self.generate_users(database : Database) : Nil
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

  def self.generate_history(history : History) : Nil
    history.new_message(sender_id: 80300, origin: 1)
    history.new_message(sender_id: 20000, origin: 4)
    history.new_message(sender_id: 60200, origin: 8)

    history.add_to_history(origin: 1, receiver: 2, receiver_id: 60200)
    history.add_to_history(origin: 1, receiver: 3, receiver_id: 20000)

    history.add_to_history(origin: 4, receiver: 5, receiver_id: 20000)
    history.add_to_history(origin: 4, receiver: 6, receiver_id: 80300)
    history.add_to_history(origin: 4, receiver: 7, receiver_id: 60200)

    history.add_to_history(origin: 8, receiver: 9, receiver_id: 20000)
    history.add_to_history(origin: 8, receiver: 10, receiver_id: 80300)

    history.add_rating(message: 2, user: 60200)
  end
end
