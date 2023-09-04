require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[On(update: Tourmaline::UpdateAction::Text)]
  class TextHandler < UpdateHandler

    def do(update : Tourmaline::Context)
      raise NotImplementedError.new("Text handling has not been implemented yet")
    end
  end
end