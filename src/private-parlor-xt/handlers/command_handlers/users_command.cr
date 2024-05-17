require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "users", config: "enable_users")]
  # A command for retrieving information about user counts
  class UsersCommand < CommandHandler
    # Returns a message containing either the total number of users or the full number of joined, left, and blacklisted users if user is authorized to see that information
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      update_user_activity(user, services)

      counts = services.database.user_counts

      if services.access.authorized?(user.rank, :Users)
        response = Format.substitute_reply(services.replies.user_count_full, {
          "joined"      => (counts[:total] - counts[:left]).to_s,
          "left"        => counts[:left].to_s,
          "blacklisted" => counts[:blacklisted].to_s,
          "total"       => counts[:total].to_s,
        })
      else
        response = Format.substitute_reply(services.replies.user_count, {
          "total" => counts[:total].to_s,
        })
      end

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
