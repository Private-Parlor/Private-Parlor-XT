require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "info", config: "enable_info")]
  # A command used to get information about one's account, or get obfuscated information about another user if one is authorized to see such information
  class InfoCommand < CommandHandler
    # An array of emoticons that start out happy then get sadder based on the number of the user's warnings
    @smileys : Array(String) = [] of String

    # Creates an instance of `InfoCommand`
    def initialize(config : Config)
      @smileys = config.smileys
    end

    # Returns a message containing information about the user's account or the user who sent the message this *message* replies to
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      if reply = message.reply_to_message
        response = ranked_info(user, message, reply, services)
      else
        response = user_info(user, services)
      end

      return unless response

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id.to_i64), user.id, response)
    end

    # Returns a `String` containing obfuscated information about a user the who sent the *reply*
    def ranked_info(user : User, message : Tourmaline::Message, reply : Tourmaline::Message, services : Services) : String?
      return unless authorized?(user, message, :RankedInfo, services)

      return unless reply_user = reply_user(user, reply, services)

      reply_user.remove_cooldown

      Format.substitute_reply(services.replies.ranked_info, {
        "oid"            => reply_user.obfuscated_id.to_s,
        "karma"          => reply_user.obfuscated_karma.to_s,
        "cooldown_until" => cooldown_until(reply_user.cooldown_until, services),
      })
    end

    # Returns a `String` containing information about the given *user*
    def user_info(user : User, services : Services) : String?
      karma_levels = services.config.karma_levels

      if karma_levels.empty?
        current_level = ""
      else
        current_level = karma_levels.find({(..), ""}) { |range, _| range === user.karma }[1]
      end

      user.remove_cooldown

      Format.substitute_reply(services.replies.user_info, {
        "oid"            => user.obfuscated_id.to_s,
        "username"       => user.formatted_name,
        "rank_val"       => user.rank.to_s,
        "rank"           => services.access.rank_name(user.rank),
        "karma"          => user.karma.to_s,
        "karma_level"    => current_level.empty? ? nil : "(#{current_level})",
        "warnings"       => user.warnings.to_s,
        "warn_expiry"    => warn_expiry(user.warn_expiry, services),
        "smiley"         => smiley(user.warnings),
        "cooldown_until" => cooldown_until(user.cooldown_until, services),
      })
    end

    # Format the cooldown until text based on the given *expiration*
    def cooldown_until(expiration : Time?, services : Services) : String
      if time = Format.time(expiration, services.locale.time_format)
        "#{services.replies.cooldown_true} #{time}"
      else
        services.replies.cooldown_false
      end
    end

    # Format the warning expiration text based on the given *expiration*
    def warn_expiry(expiration : Time?, services : Services) : String?
      if time = Format.time(expiration, services.locale.time_format)
        services.replies.info_warning.gsub("{warn_expiry}", "#{time}")
      end
    end

    # Returns a smiley based on the number of given warnings
    def smiley(warnings : Int32) : String
      case warnings
      when (0..0) then @smileys[0]
      when (1..2) then @smileys[1]
      when (2..5) then @smileys[2]
      else             @smileys[3]
      end
    end
  end
end
