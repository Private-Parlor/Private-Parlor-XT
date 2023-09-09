require "../spec_helper.cr"

module PrivateParlorXT
  # Non-singleton type of AuthorizedRanks
  class MockAuthorizedRanks < AuthorizedRanks
    def initialize(config : Config)
      @ranks = config.ranks
    end
  end
end
