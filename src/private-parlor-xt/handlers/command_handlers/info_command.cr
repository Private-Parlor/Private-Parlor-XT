require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "info", config: "enable_info")]
  class InfoCommand < CommandHandler
    @smileys : Array(String) = [] of String

    def initialize(config : Config)
      @smileys = config.smileys
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      if reply = message.reply_to_message
        ranked_info(user, message, reply, services)
      else
        user_info(user, message.message_id.to_i64, services)
      end
    end

    def ranked_info(user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services)
      return unless authorized?(user, message, :RankedInfo, services)

      return unless reply_user = get_reply_user(user, reply, services)

      update_user_activity(user, services)

      reply_user.remove_cooldown

      response = Format.substitute_reply(services.replies.ranked_info, {
        "oid"            => reply_user.get_obfuscated_id.to_s,
        "karma"          => reply_user.get_obfuscated_karma.to_s,
        "cooldown_until" => Format.format_cooldown_until(reply_user.cooldown_until, services.locale, services.replies),
      })

      services.relay.send_to_user(message.message_id.to_i64, user.id, response)
    end

    def user_info(user : User, message : MessageID, services : Services)
      update_user_activity(user, services)

      karma_levels = services.config.karma_levels

      if karma_levels.empty?
        current_level = ""
      else
        current_level = ""

        karma_levels.each_cons_pair do |lower, higher|
          if lower[0] <= user.karma && user.karma < higher[0]
            current_level = lower[1]
            break
          end
        end

        if current_level == "" && user.karma >= karma_levels.last_key
          current_level = karma_levels[karma_levels.last_key]
        elsif user.karma < karma_levels.first_key
          current_level = "???"
        end
      end

      user.remove_cooldown

      response = Format.substitute_reply(services.replies.user_info, {
        "oid"            => user.get_obfuscated_id.to_s,
        "username"       => user.get_formatted_name,
        "rank_val"       => user.rank.to_s,
        "rank"           => services.access.rank_name(user.rank),
        "karma"          => user.karma.to_s,
        "karma_level"    => current_level.empty? ? nil : "(#{current_level})",
        "warnings"       => user.warnings.to_s,
        "warn_expiry"    => Format.format_warn_expiry(user.warn_expiry, services.locale, services.replies),
        "smiley"         => Format.format_smiley(user.warnings, @smileys),
        "cooldown_until" => Format.format_cooldown_until(user.cooldown_until, services.locale, services.replies),
      })

      services.relay.send_to_user(message, user.id, response)
    end
  end
end
