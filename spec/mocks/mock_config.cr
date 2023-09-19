require "../spec_helper.cr"

module PrivateParlorXT
  class MockConfig < Config
    getter enable_mock_test : Array(Bool) = [true, true]
    getter relay_new_chat_members : Array(Bool) = [true, true]

    def initialize
      @upvote_limit_interval = 120
      @downvote_limit_interval = 120
    end
  end
end
