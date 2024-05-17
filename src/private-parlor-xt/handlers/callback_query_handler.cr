require "../handler.cr"
require "tourmaline"

module PrivateParlorXT
  # Annotation for Telegram callback query handlers
  #
  # ## Keys and Values:
  #
  # `pattern`
  # :     a `StringLiteral` or `RegexLiteral` that triggers this `CallbackHandler` when it is found in a callback query.
  #
  # `config`
  # :     `StringLiteral`, the name of the `Config` member that enables this handler.
  annotation Match
  end

  # The base class for all callback query handlers
  abstract class CallbackHandler
    # Initializes an instance of `CallbackHandler`
    #
    # The *config* can be used to modify the functionality of the handler
    def initialize(config : Config)
    end

    # The function that describes the behavior of the `CallbackHandler`
    abstract def do(callback : Tourmaline::CallbackQuery, services : Services) : Nil

    # Returns the `User` associated with the *callback* if the `User` could be found in the `Database`.
    # This will also update the `User`'s username and realname if they have changed since the last message.
    #
    # Returns `nil`  if:
    #   - `User` does not exist in the `Database`
    #   - `User` is blacklisted
    def user_from_callback(callback : Tourmaline::CallbackQuery, services : Services) : User?
      info = callback.from

      unless user = services.database.get_user(info.id.to_i64)
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      unless user.can_use_command?
        return deny_user(user, services)
      end

      user.update_names(info.username, info.full_name)

      user
    end

    # Queues a system reply when the user cannot make a callback query due to being blacklisted.
    def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.contact(services.config.blacklist_contact, services.replies),
          "reason"  => Format.reason(user.blacklist_reason, services.replies),
        })
      else
        response = services.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end
