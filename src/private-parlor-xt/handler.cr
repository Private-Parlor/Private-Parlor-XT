require "tourmaline"

module PrivateParlorXT
  # The base class for all message handlers
  abstract class Handler
    # Initializes an instance of `Handler`
    #
    # The *config* can be used to modify the functionality of the handler
    def initialize(config : Config)
    end

    # The function that describes the behavior of the `Handler`
    abstract def do(message : Tourmaline::Message, services : Services) : Nil

    # Updates the given *user's* last_active attribute to the current time
    def update_user_activity(user : User, services : Services) : Nil
      user.set_active
      services.database.update_user(user)
    end

    # Returns the given *message's* reply, if it exists
    def reply_message(user : User, message : Tourmaline::Message, services : Services) : Tourmaline::Message?
      unless message.reply_to_message
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_reply)
      end

      message.reply_to_message
    end

    # Returns the *reply_message's* `User` if he exists and the *reply_message* is still available in the `History`
    def reply_user(user : User, reply_message : Tourmaline::Message, services : Services) : User?
      reply_user_id = services.history.sender(reply_message.message_id.to_i64)

      reply_user = services.database.get_user(reply_user_id)

      unless reply_user
        return services.relay.send_to_user(ReplyParameters.new(reply_message.message_id), user.id, services.replies.not_in_cache)
      end

      reply_user
    end

    # Checks the given *message* for uniqueness and returns `true` if the message is unique
    #
    # Returns `false` if the message is unoriginal
    def unique?(user : User, message : Tourmaline::Message, services : Services, text : String? = nil) : Bool
      return true unless r9k = services.robot9000

      r9k.unique_message?(user, message, services, text)
    end
  end
end
