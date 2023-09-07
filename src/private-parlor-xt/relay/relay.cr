require "./queue.cr"

module PrivateParlorXT
  class Relay
    @queue : MessageQueue = MessageQueue.new

    private def initialize
    end

    def self.instance
      @@instance ||= new()
    end

    # TODO: Implement relay_* functions
  end
end