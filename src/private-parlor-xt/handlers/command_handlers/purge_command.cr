require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "purge", config: "enable_purge")]
  class PurgeCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return unless authorized?(user, message, :Purge, services)

      update_user_activity(user, services)

      message_count = 0

      if banned_users = services.database.get_blacklisted_users(48.hours)
        msids = Set(MessageID).new

        banned_users.each do |banned_user|
          msids = msids | services.history.get_messages_from_user(banned_user.id)
        end

        hash = services.history.get_purge_receivers(msids)
        hash.each do |receiver, msids_to_delete|
          message_count += msids.size
          msids_to_delete.each_slice(100) do |slice|
            services.relay.purge_messages(receiver, slice)
          end
        end

        msids.each do |msid|
          services.history.delete_message_group(msid)
        end
      end

      response = Format.substitute_reply(services.replies.purge_complete, {
        "msgs_deleted" => message_count.to_s,
      })

      services.relay.delay_send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
