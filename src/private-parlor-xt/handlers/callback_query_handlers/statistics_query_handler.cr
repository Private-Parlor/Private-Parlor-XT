require "../../callback_query_handler.cr"
require "tourmaline"

module PrivateParlorXT
  class StatisticsQueryHandler < CallbackHandler
    def do(callback : Tourmaline::CallbackQuery, services : Services) : Nil
      return unless user = get_user_from_callback(callback, services)

      return unless message = callback.message

      return unless data = callback.data

      return unless stats = services.stats

      return unless (split = data.split('=')) && split.size == 2

      next_screen = Statistics::StatScreens.parse(split[1])

      response = stats.get_statistic_screen(next_screen, services)

      reply_markup = stats.keyboard_markup(next_screen, services)

      services.relay.edit_message_text(user.id, response, reply_markup, message.message_id.to_i64)
    end
  end
end
