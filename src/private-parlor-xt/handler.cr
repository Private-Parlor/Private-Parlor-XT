require "tourmaline"

module PrivateParlorXT
  abstract class Handler
    def initialize(config : Config)
    end

    abstract def do(message : Tourmaline::Message, services : Services)

    def update_user_activity(user : User, services : Services)
      user.set_active
      services.database.update_user(user)
    end

    def get_reply_message(user : User, message : Tourmaline::Message, services : Services) : Tourmaline::Message?
      unless message.reply_to_message
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_reply)
        return
      end

      message.reply_to_message
    end

    def get_reply_user(user : User, reply_message : Tourmaline::Message, services : Services) : User?
      reply_user_id = services.history.get_sender(reply_message.message_id.to_i64)

      reply_user = services.database.get_user(reply_user_id)

      unless reply_user
        services.relay.send_to_user(ReplyParameters.new(reply_message.message_id), user.id, services.replies.not_in_cache)
        return
      end

      reply_user
    end
  end
end
