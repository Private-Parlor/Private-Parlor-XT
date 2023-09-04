require "tourmaline"

module PrivateParlorXT
  annotation RespondsTo
  end

  abstract class CommandHandler

    abstract def do(ctx : Context)

  end
end