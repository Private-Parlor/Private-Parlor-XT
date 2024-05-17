require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["stats", "statistics"], config: "enable_stats")]
  # A command used for getting statistics about the bot
  class StatsCommand < CommandHandler
    # Returns a message containing general bot statistics if *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      unless stats = services.stats
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      response = stats.config_screen(services)

      reply_markup = stats.keyboard_markup(Statistics::StatScreens::General, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response, reply_markup)
    end
  end
end
