require "tourmaline"

module PrivateParlorXT
  annotation RespondsTo
  end

  annotation On
  end

  abstract class CommandHandler

    abstract def do(ctx : Context)

  end

  abstract class UpdateHandler

    abstract def do(update : Context)

  end
end