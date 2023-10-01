require "./private-parlor-xt/**"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  VERSION = "0.1.0"

  services = initialize_services

  # 30 messages every second; going above may result in rate limits
  sending_routine = Tasker.every(1.second) do
    30.times do
      break if services.relay.send_messages(services)
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

  def self.terminate_program(routine : Tasker::Task, services : Services)
    services.relay.stop_polling

    routine.cancel

    # Send last messages in queue
    loop do
      break if services.relay.send_messages(services) == true
    end

    # Bot stopped polling from SIGINT/SIGTERM, shut down
    # Rescue if database unique constraint was encountered during runtime
    begin
      services.database.close
    rescue
      nil
    end
    Log.info { "Sent last messages in queue. Shutting down..." }
    exit
  end
end
