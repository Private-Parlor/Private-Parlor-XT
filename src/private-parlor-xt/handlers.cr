require "tourmaline"

module PrivateParlorXT
  annotation RespondsTo
  end

  annotation On
  end

  abstract class CommandHandler

    abstract def initialize(config : Config)

    abstract def do(ctx : Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)

  end

  abstract class UpdateHandler

    abstract def initialize(config : Config)

    abstract def do(update : Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)

  end
end