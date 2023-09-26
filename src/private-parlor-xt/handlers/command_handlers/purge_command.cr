require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "purge", config: "enable_purge")]
  class PurgeCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Purge, services)

      update_user_activity(user, services)

      message_count = 0

      if banned_users = services.database.get_blacklisted_users(48.hours)
        banned_users.each do |banned_user|
          services.history.get_messages_from_user(banned_user.id).each do |msid|
            delete_messages(msid, banned_user.id, banned_user.debug_enabled, true, services)
            message_count += 1
          end
        end
      end

      response = Format.substitute_message(services.replies.purge_complete, {
        "msgs_deleted" => message_count.to_s,
      })

      # TODO: Move this message to the end of the queue
      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
