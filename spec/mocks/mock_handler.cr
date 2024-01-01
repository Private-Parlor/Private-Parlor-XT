require "../spec_helper.cr"

module PrivateParlorXT
  class MockHandler < Handler
    def initialize(config : Config)
    end

    def do(message : Tourmaline::Message, services : Services)
    end
  end
end
