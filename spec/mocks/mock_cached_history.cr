require "../spec_helper.cr"

module PrivateParlorXT

  # Non-singleton type of CachedHistory
  class MockCachedHistory < CachedHistory
    
    def initialize(config : Config)
      @lifespan = config.message_lifespan.hours
    end
  end
end