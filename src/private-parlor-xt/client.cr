require "tourmaline"

module PrivateParlorXT
  class Client < Tourmaline::Client
    @poller : Tourmaline::Poller?

    def poll : Nil
      @poller = Tourmaline::Poller.new(self).start
    end

    def stop : Nil
      return unless poller = @poller
      poller.stop
    end
  end
end
