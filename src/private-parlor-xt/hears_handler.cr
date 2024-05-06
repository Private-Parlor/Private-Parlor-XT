require "./handler.cr"
require "tourmaline"

module PrivateParlorXT

  # Annotation for Telegram hears handlers
  # 
  # ## Keys and Values:
  #
  # `pattern`
  # :     a `StringLiteral` or `RegexLiteral` that triggers this `HearsHandler` when it is found in a message text.
  #       A `RegexLiteral` will match patterns inside text, whereas a `StringLiteral` will match patterns at the start of text.
  #
  # `config`
  # :     `String`, the name of the `Config` member that enables this handler.
  #       Handlers should be configurable, though a value is not required here to compile or be used in the program.
  #
  # `command`
  # :     a `BoolLiteral` which determines if the `HearsHandler` functions as a command. 
  #       If `true`, a "command_disabled" reply will be sent if this handler is not toggled.
  annotation Hears
  end

  # A base class for handling messages whose text matches a certain pattern.
  # 
  # Handlers that are meant to match patterns in text should inherit from this class, 
  # and include an `Hears` annotation to have it be usable by the bot.
  abstract class HearsHandler < Handler

    # Queues a system reply when the message matched is from a user who is blacklisted
    def deny_user(user : User, services : Services) : Nil
      return unless user.blacklisted?

      response = Format.substitute_reply(services.replies.blacklisted, {
        "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
        "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
      })

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end
