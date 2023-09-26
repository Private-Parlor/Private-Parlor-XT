require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["karma_info", "karmainfo"], config: "enable_karma_info")]
  class KarmaInfoCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      karma_levels = services.config.karma_levels

      return if karma_levels.empty?

      update_user_activity(user, services)

      current_level = next_level = {0, ""}
      percentage = 0.0_f32

      karma_levels.each_cons_pair do |lower, higher|
        if lower[0] <= user.karma && user.karma < higher[0]
          current_level = lower
          next_level = higher

          percentage = ((user.karma - lower[0]) * 100) / (higher[0] - lower[0]).to_f32
          break
        end
      end

      # Karma lies outside of bounds
      if current_level == next_level
        if (lowest = karma_levels.first?) && user.karma < lowest[0]
          current_level = {user.karma, "???"}
          next_level = lowest
        elsif (highest = {karma_levels.last_key, karma_levels.last_value}) && user.karma >= highest[0]
          current_level = {user.karma, highest[1]}
          next_level = {highest[0], "???"}
          percentage = 100.0_f32
        end
      end

      response = Format.substitute_reply(services.replies.karma_info, {
        "current_level" => current_level[1],
        "next_level"    => next_level[1],
        "karma"         => user.karma.to_s,
        "limit"         => next_level[0].to_s,
        "loading_bar"   => Format.format_karma_loading_bar(percentage, services.locale),
        "percentage"    => "#{percentage.format(decimal_places: 1, only_significant: true)}",
      })

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end
  end
end
