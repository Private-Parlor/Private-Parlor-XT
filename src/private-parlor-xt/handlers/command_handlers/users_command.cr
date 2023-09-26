require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "users", config: "enable_users")]
  class UsersCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      update_user_activity(user, services)

      counts = services.database.get_user_counts

      if authorized?(user, message, :Users, services)
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

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
