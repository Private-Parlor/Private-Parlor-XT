require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: Tourmaline::UpdateAction::Text, config: "relay_text")]
  class TextHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      raise NotImplementedError.new("Text handling has not been implemented yet")
    end
  end
end
