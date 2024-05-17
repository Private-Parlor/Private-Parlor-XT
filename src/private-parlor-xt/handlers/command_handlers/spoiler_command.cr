require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "spoiler", config: "enable_spoiler")]
  # A command used to add or remove a spoiler on a message after it has been sent.
  class SpoilerCommand < CommandHandler
    # Adds a spoiler to the given *message* if it does not have one, or removes it if it does, and *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Spoiler, services)

      return unless reply = reply_message(user, message, services)

      if reply.forward_origin
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      unless services.history.sender(reply.message_id.to_i64)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.not_in_cache)
      end

      # Prevent spoiling messages that were not sent by the bot
      if (from = reply.from) && from.id == user.id
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      unless input = message_input(reply)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      spoil_messages(reply, user, input, services)

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.success)
    end

    # Returns a `Tourmaline::InputMedia` from the media contents of the given *message*
    #
    # Returns `nil` unless message contains a photo, video, or animation/GIF
    def message_input(message : Tourmaline::Message) : Tourmaline::InputMedia?
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
      return unless reply_msids = services.history.receivers(reply.message_id.to_i64)

      if reply.has_media_spoiler?
        log = Format.substitute_message(services.logs.unspoiled, {
          "id"   => user.id.to_s,
          "name" => user.formatted_name,
          "msid" => reply.message_id.to_s,
        })
      else
        input.has_spoiler = true

        log = Format.substitute_message(services.logs.spoiled, {
          "id"   => user.id.to_s,
          "name" => user.formatted_name,
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
