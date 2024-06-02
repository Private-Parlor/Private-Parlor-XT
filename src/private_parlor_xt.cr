require "./private-parlor-xt/**"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  VERSION = "1.2.2"

  services = initialize_bot

  sending_routine = Tasker.every(1.second) do
    loop do
      break if services.relay.send_message(services)
    end
  end

  Signal::INT.trap do
    terminate_program(sending_routine, services)
  end

  Signal::TERM.trap do
    terminate_program(sending_routine, services)
  end

  begin
    log = Format.substitute_message(services.logs.start, {"version" => VERSION})
    services.relay.log_output(log)
  rescue ex
    Log.error(exception: ex) {
      "Failed to send message to log channel; check that the bot is an admin in the chanel and can post messages"
    }
    services.relay.set_log_channel("")
  end

  services.relay.start_polling

  sleep

  # Stop the message sending routine, send remaining messages in the queue
  # and terminate the program
  def self.terminate_program(routine : Tasker::Task, services : Services) : Nil
    services.relay.stop_polling

    routine.cancel

    # Send last messages in queue
    loop do
      break if services.relay.send_message(services)
    end

    # Bot stopped polling from SIGINT/SIGTERM, shut down
    # Rescue if database unique constraint was encountered during runtime
    begin
      services.database.close
    rescue
      nil
    end
    Log.notice { "Sent last messages in queue. Shutting down..." }
    exit
  end

  # Reads from the config file and initialize `Services`, recurring tasks, and bot handlers
  #
  # Returns the initialized `Services` object
  def self.initialize_bot(client : Client? = nil) : Services
    config = Config.parse_config

    unless client
      client = Client.new(config.token)
    end

    client.default_parse_mode = Tourmaline::ParseMode::MarkdownV2

    services = Services.new(config, client)

    start_tasks(config, services)

    initialize_handlers(client, config, services)

    services
  end

  # Initializes recurring tasks, such as:
  #   - Warning expiration
  #   - Message expiration (if toggled)
  #   - Spam cooldown expiration (if toggled)
  #   - Inactive user kicking (if toggled)
  def self.start_tasks(config : Config, services : Services) : Nil
    Tasker.every(15.minutes) {
      services.database.expire_warnings(config.warn_lifespan.hours)
    }

    if config.message_lifespan > 0
      Tasker.every(config.message_lifespan.hours * (1/4)) {
        services.history.expire
      }
    end

    if spam = services.spam
      Tasker.every(config.spam_interval.seconds) {
        spam.expire
      }
    end

    if config.inactivity_limit > 0
      Tasker.every(6.hours) {
        kick_inactive_users(config.inactivity_limit.days, services)
      }
    end
  end
end
