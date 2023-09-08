require "./private-parlor-xt/**"
require "tourmaline"

module PrivateParlorXT
  VERSION = "0.1.0"

  config = Config.parse_config()
  locale = Locale.parse_locale(config.locale)
  database = SQLiteDatabase.instance(DB.open("sqlite3://#{config.database}"))
  
  if config.database_history
    history = SQLiteHistory.instance(config.message_lifespan.hours, DB.open("sqlite3://#{config.database}"))
  else
    history = CachedHistory.instance(config.message_lifespan.hours)
  end

  access = AuthorizedRanks.instance(config.ranks)

  relay = Relay.instance

  client = Tourmaline::Client.new(config.token)

  initialize_handlers(client, config, relay, access, database, history, locale)

  client.poll
end
