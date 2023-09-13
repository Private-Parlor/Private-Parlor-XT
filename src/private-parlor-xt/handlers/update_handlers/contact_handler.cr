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

      new_message = history.new_message(user.id, message.message_id.to_i64)

      if reply = message.reply_to_message
        reply_msids = history.get_all_receivers(reply.message_id.to_i64)

        if reply_msids.empty?
          relay.send_to_user(new_message, user.id, locale.replies.not_in_cache)
          history.delete_message_group(new_message)
          return
        end
      end

      user.set_active
      database.update_user(user)
      
      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      relay.send_contact(
        new_message,
        user,
        receivers,
        reply_msids,
        contact,
      )
    end
  end
end