require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "info", config: "enable_info")]
  class InfoCommand < CommandHandler
    @karma_levels : Hash(Int32, String) = {} of Int32 => String
    @smileys : Array(String) = [] of String

    def initialize(config : Config)
      @blacklist_contact = config.blacklist_contact
      @karma_levels = config.karma_levels
      @smileys = config.smileys
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      message, user = get_message_and_user(ctx, database, relay, locale)
      return unless message && user

      if reply = message.reply_to_message
        ranked_info(
          user,
          message.message_id.to_i64,
          reply.message_id.to_i64,
          access, database,
          history,
          relay,
          locale
        )
      else
        user_info(user, message.message_id.to_i64, database, locale, access, relay)
      end
    end

    private def ranked_info(user : User, message : MessageID, reply : MessageID, access : AuthorizedRanks, database : Database, history : History, relay : Relay, locale : Locale)
      unless access.authorized?(user.rank, :RankedInfo)
        return relay.send_to_user(message, user.id, locale.replies.fail)
      end
      unless reply_user = database.get_user(history.get_sender(reply))
        return relay.send_to_user(message, user.id, locale.replies.not_in_cache)
      end

      user.set_active
      database.update_user(user)

      reply_user.remove_cooldown

      response = Format.substitute_message(locale.replies.ranked_info, {
        "oid"            => reply_user.get_obfuscated_id.to_s,
        "karma"          => reply_user.get_obfuscated_karma.to_s,
        "cooldown_until" => Format.format_cooldown_until(reply_user.cooldown_until, locale),
      })

      relay.send_to_user(message, user.id, response)
    end

    private def user_info(user : User, message : MessageID, database : Database, locale : Locale, access : AuthorizedRanks, relay : Relay)
      user.set_active
      database.update_user(user)

      if !@karma_levels.empty?
        current_level = ""

        @karma_levels.each_cons_pair do |lower, higher|
          if lower[0] <= user.karma && user.karma < higher[0]
            current_level = lower[1]
            break
          end
        end

        if current_level == "" && user.karma >= @karma_levels.last_key
          current_level = @karma_levels[@karma_levels.last_key]
        elsif user.karma < @karma_levels.first_key
          current_level = "???"
        end
      else
        current_level = ""
      end

      user.remove_cooldown

      response = Format.substitute_message(locale.replies.user_info, {
        "oid"            => user.get_obfuscated_id.to_s,
        "username"       => user.get_formatted_name,
        "rank_val"       => user.rank.to_s,
        "rank"           => access.rank_name(user.rank),
        "karma"          => user.karma.to_s,
        "karma_level"    => current_level.empty? ? nil : "(#{current_level})",
        "warnings"       => user.warnings.to_s,
        "warn_expiry"    => Format.format_warn_expiry(user.warn_expiry, locale),
        "smiley"         => Format.format_smiley(user.warnings, @smileys),
        "cooldown_until" => Format.format_cooldown_until(user.cooldown_until, locale),
      })

      relay.send_to_user(message, user.id, response)
    end
  end
end
