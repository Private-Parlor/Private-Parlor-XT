require "./private-parlor-xt/**"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  VERSION = "0.1.0"

  config = Config.parse_config
  locale = Locale.parse_locale(Path["./locales"], config.locale)
  database = SQLiteDatabase.instance(DB.open("sqlite3://#{config.database}"))

  if config.database_history
    history = SQLiteHistory.instance(config.message_lifespan.hours, DB.open("sqlite3://#{config.database}"))
  else
    history = CachedHistory.instance(config.message_lifespan.hours)
  end

  access = AuthorizedRanks.instance(config.ranks)

  client = Client.new(config.token)
  client.default_parse_mode = Tourmaline::ParseMode::HTML # TODO: Change to MarkdownV2

  relay = Relay.instance(config.log_channel, client)

  initialize_handlers(client, config, relay, access, database, history, locale)

  # 30 messages every second; going above may result in rate limits
  sending_routine = Tasker.every(500.milliseconds) do
    15.times do
      break if relay.send_messages(database, locale, history)
    end
  end

  Signal::INT.trap do
    terminate_program(client, sending_routine, relay, database, locale, history)
  end

  Signal::TERM.trap do
    terminate_program(client, sending_routine, relay, database, locale, history)
  end

  begin
    log = Format.substitute_message(locale.logs.start, locale, {"version" => VERSION})
    relay.log_output(log)
  rescue ex
    Log.error(exception: ex) {
      "Failed to send message to log channel; check that the bot is an admin in the chanel and can post messages"
    }
    relay.set_log_channel("")
  end

  client.poll

  sleep

  def self.terminate_program(client : Client, routine : Tasker::Task, relay : Relay, database : Database, locale : Locale, history : History)
    client.stop

    routine.cancel

    # Send last messages in queue
    loop do
      break if relay.send_messages(database, locale, history) == true
    end

    # Bot stopped polling from SIGINT/SIGTERM, shut down
    # Rescue if database unique constraint was encountered during runtime
    begin
      database.close
    rescue
      nil
    end
    Log.info { "Sent last messages in queue. Shutting down..." }
    exit
  end
end
