require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[RespondsTo(command: ["start"])]
  class StartCommand < CommandHandler

    def do(ctx : Tourmaline::Context)
      raise NotImplementedError.new("StartCommand has not been implemented yet")
    end
  end
end