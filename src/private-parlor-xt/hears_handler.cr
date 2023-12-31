require "./handler.cr"
require "tourmaline"

module PrivateParlorXT
  annotation Hears
  end

  abstract class HearsHandler < Handler
    def get_message_and_user(message : Tourmaline::Message, services : Services) : Tuple(Tourmaline::Message?, User?)
      unless info = message.from
        return nil, nil
      end

      unless user = services.database.get_user(info.id.to_i64)
        services.relay.send_to_user(nil, info.id.to_i64, services.replies.not_in_chat)
        return message, nil
      end

      user.update_names(info.username, info.full_name)

      return message, user
    end

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
