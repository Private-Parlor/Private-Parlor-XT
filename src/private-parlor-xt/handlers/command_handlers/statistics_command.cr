require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["stats", "statistics"], config: "enable_stats")]
  class StatsCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      unless stats = services.stats
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      response = stats.format_config_data(services)

      reply_markup = stats.keyboard_markup(Statistics::StatScreens::General, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response, reply_markup)
    end
  end
end
