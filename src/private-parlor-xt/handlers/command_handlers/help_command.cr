require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "help", config: "enable_help")]
  class HelpCommand < CommandHandler
    def initialize(config : Config)
      @blacklist_contact = config.blacklist_contact
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      user.set_active
      database.update_user(user)

      relay.send_to_user(message.message_id.to_i64, user.id, Format.format_help(user, access.ranks, locale))
    end
  end
end