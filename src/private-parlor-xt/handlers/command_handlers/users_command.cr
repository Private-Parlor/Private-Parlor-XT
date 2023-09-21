require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "users", config: "enable_users")]
  class UsersCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      user.set_active
      database.update_user(user)

      counts = database.get_user_counts

      if access.authorized?(user.rank, :Users)
        response = Format.substitute_message(locale.replies.user_count_full, {
          "joined"      => (counts[:total] - counts[:left]).to_s,
          "left"        => counts[:left].to_s,
          "blacklisted" => counts[:blacklisted].to_s,
          "total"       => counts[:total].to_s,
        })
      else
        response = Format.substitute_message(locale.replies.user_count, {
          "total" => counts[:total].to_s,
        })
      end

      relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
