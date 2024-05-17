require "./private-parlor-xt/**"
require "tourmaline"
require "tasker"

module PrivateParlorXT
  VERSION = "1.2.0"

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
  def self.terminate_program(routine : Tasker::Task, services : Services)
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
end
