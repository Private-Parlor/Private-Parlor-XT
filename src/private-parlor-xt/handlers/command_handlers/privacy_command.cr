require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "privacy", config: "enable_privacy_policy")]
  # A command used to view the privacy policy of the bot
  #
  # This command is required for all Telegram bots according to https://t.me/BotNews/96
  #
  # All bots require a privacy policy that is easily accessible
  # This command is usuable by any user of the bot, regardless of if he is blacklisted, left, or neither
  #
  # The Privacy Policy is defined in the locale files; if you modify the program in how it handles data, the Privacy Policy may need to be updated
  #
  # Contact information is defined by the `blacklist_contact` configured value
  class PrivacyPolicyCommand < CommandHandler
    # Returns a message containing this bot's Privacy Policy
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless info = message.from

      if text = message.text || message.caption
        return unless text.starts_with?('/')
      end

      uid = info.id.to_i64

      if user = services.database.get_user(uid)
        update_user_activity(user, services)
      end

      services.relay.send_to_user(
        ReplyParameters.new(message.message_id),
        uid,
        Format.substitute_reply(services.replies.privacy_policy, {
          "contact" => Format.contact(services.config.blacklist_contact, services.replies),
        })
      )
    end
  end
end
