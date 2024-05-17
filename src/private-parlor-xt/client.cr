require "tourmaline"

module PrivateParlorXT
  # Handles polling Telegram for updates and sending responses
  class Client < Tourmaline::Client
    # Returns the `Tourmaline::Poller` object associated with this client, if it is available
    @poller : Tourmaline::Poller?

    # Initialize the `poller` and start polling for updates
    def poll : Nil
      @poller = Tourmaline::Poller.new(self).start
    end

    # Stop polling for updates
    def stop : Nil
      return unless poller = @poller
      poller.stop
    end
  end
end

module Tourmaline
  class Message
    # Set to `true` if the message is preformatted (in case a command handler alters the message before an update handler gets it)
    #
    # Set to `false` otherwise
    property? preformatted : Bool? = false
  end
end
