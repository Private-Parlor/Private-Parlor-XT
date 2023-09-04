require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[RespondsTo(command: ["stop"])]
  class StopCommand < CommandHandler

    def do(ctx : Tourmaline::Context)
      raise NotImplementedError.new("StopCommand has not been implemented yet")
    end
  end
end