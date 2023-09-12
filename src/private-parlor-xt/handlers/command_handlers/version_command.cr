require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "version", config: "enable_version")]
  class VersionCommand < CommandHandler

    def initialize(config : Config)
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      user.set_active
      database.update_user(user)

      relay.send_to_user(message.message_id.to_i64, user.id, Format.format_version)
    end
  end
end