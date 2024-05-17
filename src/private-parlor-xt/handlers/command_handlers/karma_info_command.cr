require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["karma_info", "karmainfo"], config: "enable_karma_info")]
  # A command used to obtain information about one's current karma and karma level progress
  class KarmaInfoCommand < CommandHandler
    # Returns a message containing the user's karma level progress if karma levels are not empty
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      karma_levels = services.config.karma_levels

      return if karma_levels.empty?

      update_user_activity(user, services)

      current_level = next_level = ""
      percentage = 0.0_f32
      limit = 0

      level_keys = karma_levels.keys

      level_keys.each_with_index do |range, index|
        next unless range === user.karma

        current_level = karma_levels[range]

        if range == karma_levels.last_key
          next_level = "???"
          limit = "???"
          percentage = 100.0_f32
        elsif range == karma_levels.first_key
          next_range = level_keys[index + 1]
          next_level = karma_levels[next_range]
          limit = next_range.begin

          range_begin = range.begin.to_i64

          percentage = ((-range_begin + user.karma) * 100) / (-range_begin + next_range.begin).to_f32
        else
          next_range = level_keys[index + 1]
          next_level = karma_levels[next_range]
          limit = next_range.begin

          percentage = ((user.karma - range.begin) * 100) / (next_range.begin - range.begin).to_f32
        end
      end

      response = Format.substitute_reply(services.replies.karma_info, {
        "current_level" => current_level,
        "next_level"    => next_level,
        "karma"         => user.karma.to_s,
        "limit"         => limit.to_s,
        "loading_bar"   => karma_loading_bar(percentage, services),
        "percentage"    => percentage.format(decimal_places: 1, only_significant: true),
      })

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
    # Formats a loading bar for the /karmainfo command
    def karma_loading_bar(percentage : Float32, services : Services) : String
      pips = (percentage.floor.to_i).divmod(10)

      if pips[0] != 10
        String.build(10) do |str|
          str << services.locale.loading_bar[2] * pips[0]

          if pips[1] >= 5
            str << services.locale.loading_bar[1]
          else
            str << services.locale.loading_bar[0]
          end

          str << services.locale.loading_bar[0] * (10 - (pips[0] + 1))
        end
      else
        services.locale.loading_bar[2] * 10
      end
    end
  end
end
