require "../spec_helper.cr"

module PrivateParlorXT
  class MockHandler < Handler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
    end
  end
end
