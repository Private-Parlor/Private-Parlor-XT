require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Contact, config: "relay_contact")]
  class ContactHandler < UpdateHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless is_authorized?(user, message, :Contact, services)
      
      return if is_spamming?(user, message, services)

      return unless contact = message.contact

      if reply = message.reply_to_message
        return unless reply_msids = get_reply_receivers(reply, message, user, services)
      end

      new_message = services.history.new_message(user.id, message.message_id.to_i64)

      update_user_activity(user, services)

      receivers = get_message_receivers(user, services)

      services.relay.send_contact(
        new_message,
        user,
        receivers,
        reply_msids,
        contact,
      )
    end

    def is_spamming?(user : User, message : Tourmaline::Message, services : Services) : Bool
      return false unless spam = services.spam
      
      if spam.spammy_contact?(user.id)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      false
    end
  end
end
