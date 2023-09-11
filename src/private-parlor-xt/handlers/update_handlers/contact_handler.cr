require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT

  @[On(update: :Contact, config: "relay_contact")]
  class ContactHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Contact)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "contact"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      return if message.forward_date
      return unless contact = message.contact

      if spam && spam.spammy_contact?(user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      user.set_active
      database.update_user(user)

      if reply = message.reply_to_message
        reply = reply.message_id.to_i64
      else
        reply = nil
      end

      relay.send_contact(
        reply,
        user,
        history.new_message(user.id, message.message_id.to_i64),
        contact,
        locale,
        history,
        database
      )
    end
  end
end