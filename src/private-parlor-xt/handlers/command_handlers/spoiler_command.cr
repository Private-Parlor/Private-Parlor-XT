require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "spoiler", config: "enable_spoiler")]
  class SpoilerCommand < CommandHandler
    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Spoiler, services)

      return unless reply = get_reply_message(user, message, services)

      if reply.forward_date
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.fail)
      end
      unless services.history.get_sender(reply.message_id.to_i64)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.not_in_cache)
      end

      # Prevent spoiling messages that were not sent from the bot
      unless (from = reply.from) && from.id == services.relay.get_client_user.id
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      unless input = get_message_input(reply)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.fail)
      end

      spoil_messages(reply, user, input, services)

      services.relay.delay_send_to_user(message.message_id.to_i64, user.id, services.replies.success)
    end

    def get_message_input(message : Tourmaline::Message) : Tourmaline::InputMedia?
      if media = message.photo.last?
        Tourmaline::InputMediaPhoto.new(media.file_id, caption: message.caption, caption_entities: message.caption_entities)
      elsif media = message.video
        Tourmaline::InputMediaVideo.new(media.file_id, caption: message.caption, caption_entities: message.caption_entities)
      elsif media = message.animation
        Tourmaline::InputMediaAnimation.new(media.file_id, caption: message.caption, caption_entities: message.caption_entities)
      end
    end

    # Spoils the given media message for all receivers by editing the media with the given input.
    def spoil_messages(reply : Tourmaline::Message, user : User, input : Tourmaline::InputMedia, services : Services) : Nil
      return unless reply_msids = services.history.get_all_receivers(reply.message_id.to_i64)

      if reply.has_media_spoiler?
        log = Format.substitute_message(services.logs.unspoiled, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "msid" => reply.message_id.to_s,
        })
      else
        input.has_spoiler = true

        log = Format.substitute_message(services.logs.spoiled, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "msid" => reply.message_id.to_s,
        })
      end

      # Messages qeueued from this block may throw a MessageCantBeEdited error
      # when message is a forward, but will be caught by the message sending routine
      reply_msids.each do |receiver, receiver_message|
        services.relay.edit_message_media(receiver, input, receiver_message)
      end

      services.relay.log_output(log)
    end
  end
end
