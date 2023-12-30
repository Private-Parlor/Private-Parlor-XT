require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "purge", config: "enable_purge")]
  class PurgeCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      message, user = get_message_and_user(message, services)
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

      response = Format.substitute_reply(services.replies.purge_complete, {
        "msgs_deleted" => message_count.to_s,
      })

      services.relay.delay_send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
