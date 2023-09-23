require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "version", config: "enable_version")]
  class VersionCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      update_user_activity(user, services)

      services.relay.send_to_user(message.message_id.to_i64, user.id, Format.format_version)
    end
  end
end
