require "../spec_helper.cr"

module PrivateParlorXT

  @[RespondsTo(command: ["mock_test"])]
  class MockCommandHandler < CommandHandler
    
    def do(ctx : Tourmaline::Context)
    end
  end
end