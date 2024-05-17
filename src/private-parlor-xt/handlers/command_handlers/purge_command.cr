require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "purge", config: "enable_purge")]
  # A command used to delete all messages sent by recently blacklisted users in one go
  class PurgeCommand < CommandHandler
    # Deletes all messages sent by recently blacklisted users for everybody, if *message* meets requirements
    #
    # A possible `Tourmaline::Error::MessageCantBeDeleted` error can occur when a message's lifespan is 48 hours or greater.
    # This happens because messages older than 48 hours cannot be deleted for everybody.
    # As this function deletes messages in descending order (most recent messages are deleted first), the function will error out
    # when deleting the oldest messages; this is intended due to Telegram API limitations.
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Purge, services)

      update_user_activity(user, services)

      message_count = 0

      if banned_users = services.database.blacklisted_users(48.hours)
        msids = Set(MessageID).new

        banned_users.each do |banned_user|
          msids = msids | services.history.messages_from_user(banned_user.id)
        end

        hash = services.history.purge_receivers(msids)
        hash.each do |receiver, msids_to_delete|
          msids_to_delete.each_slice(100) do |slice|
            services.relay.purge_messages(receiver, slice)
          end
        end

        msids.each do |msid|
          services.history.delete_message_group(msid)
        end

        message_count += msids.size
      end

      response = Format.substitute_reply(services.replies.purge_complete, {
        "msgs_deleted" => message_count.to_s,
      })

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
