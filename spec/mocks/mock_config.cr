require "../spec_helper.cr"

module PrivateParlorXT
  class MockConfig < Config
    getter enable_mock_test : Array(Bool) = [true, true]
    getter enable_mockpattern : Array(Bool) = [true, true]
    getter relay_new_chat_members : Array(Bool) = [true, true]

    def initialize(
      @upvote_limit_interval = 120,
      @downvote_limit_interval = 120,
      @media_limit_period = 120,
      @default_rank = 0,
      @registration_open = true,
      @pseudonymous = false,
      @media_spoilers = false,
      @karma_reasons = false,
      @salt = "",
      @linked_network = {} of String => String,
      @karma_economy = nil,
      @karma_levels = {
        (Int32::MIN...0) => "Junk",
        (0...10) => "Normal",
        (10...20) => "Common",
        (20...30) => "Uncommon",
        (30...40) => "Rare",
        (40...50) => "Legendary",
        (50..Int32::MAX) => "Unique",
      }
    )
    end
  end
end
