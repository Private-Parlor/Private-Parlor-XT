require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  annotation Match
  end

  abstract class CallbackHandler
    def initialize(config : Config)
    end

    abstract def do(callback : Tourmaline::CallbackQuery, services : Services)

    def get_user_from_callback(callback : Tourmaline::CallbackQuery, services : Services) : User?
      return unless info = callback.from

      unless user = services.database.get_user(info.id.to_i64)
        return services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
      end

      unless user.can_chat?
        return deny_user(user, services) 
      end

      user.update_names(info.username, info.full_name)

      user
    end

    def deny_user(user : User, services : Services) : Nil
      if user.blacklisted?
        response = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => Format.format_contact_reply(services.config.blacklist_contact, services.replies),
          "reason"  => Format.format_reason_reply(user.blacklist_reason, services.replies),
        })
      else
        response = services.replies.not_in_chat
      end

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end