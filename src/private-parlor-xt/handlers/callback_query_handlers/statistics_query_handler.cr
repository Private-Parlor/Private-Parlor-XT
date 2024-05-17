require "../../callback_query_handler.cr"
require "tourmaline"

module PrivateParlorXT

  # A `CallbackHandler` that responds to callback queries originating from the inline keyboard buttons found on the message produced by `StatsCommand`
  class StatisticsQueryHandler < CallbackHandler
    # Parses the query found in *callback* and returns the associated statistics screen if *callback* meets requirements
    def do(callback : Tourmaline::CallbackQuery, services : Services) : Nil
      return unless user = user_from_callback(callback, services)

      return unless message = callback.message

      return unless data = callback.data

      return unless stats = services.stats

      return unless (split = data.split('=')) && split.size == 2

      next_screen = Statistics::StatScreens.parse(split[1])

      if next_screen == Statistics::StatScreens::Users && !services.access.authorized?(user.rank, CommandPermissions::Users)
        response = stats.users_screen(services)
      else
        response = stats.statistic_screen(next_screen, services)
      end

      reply_markup = stats.keyboard_markup(next_screen, services)

      services.relay.edit_message_text(user.id, response, reply_markup, message.message_id.to_i64)
    end
  end
end
