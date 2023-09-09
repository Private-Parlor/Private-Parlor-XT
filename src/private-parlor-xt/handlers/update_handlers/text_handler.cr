require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Text, config: "relay_text")]
  class TextHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :text)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "text"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end
      
      return if message.forward_date
      return unless text = message.text

      if spam && spam.spammy_text?(user.id, text)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      # TODO: Add R9K check hook

      text = check_text(text, user, message.message_id.to_i64, message.entities)

      # TODO: Add pseudonymous hook

      # TODO: Add R9K write hook

      user.set_active
      database.update_user(user)

      if reply = message.reply_to_message
        reply = reply.message_id.to_i64
      else
        reply = nil
      end

      relay.send_text(
        reply,
        user,
        history.new_message(user.id, message.message_id.to_i64),
        text,
        locale,
        history,
        database
      )
    end

    private def check_text(text : String, user : User, msid : MessageID, entities : Array(Tourmaline::MessageEntity)) : String
      # TODO: Implement text checks
      text
    end
  end
end
