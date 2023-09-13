require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Animation, config: "relay_animation")]
  class AnimationHandler < UpdateHandler
    @entity_types : Array(String)
    @linked_network : Hash(String, String) = {} of String => String
    @allow_spoilers : Bool? = false

    def initialize(config : Config)
      @entity_types = config.entities
      @linked_network = config.linked_network
      @allow_spoilers = config.media_spoilers
    end

    def do(update : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale, spam : SpamHandler?)
      message, user = get_message_and_user(update, database, relay, locale)
      return unless message && user

      unless access.authorized?(user.rank, :Animation)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "animation"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      return if message.forward_date
      return if message.media_group_id

      if spam && spam.spammy_animation?(user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      return unless animation = message.animation

      caption = message.caption || ""

      # TODO: Add R9K check hook

      caption, entities = check_text(caption, user, message, message.caption_entities, relay, locale)

      # TODO: Add pseudonymous hook

      new_message = history.new_message(user.id, message.message_id.to_i64)

      if reply = message.reply_to_message
        reply_msids = history.get_all_receivers(reply.message_id.to_i64)

        if reply_msids.empty?
          relay.send_to_user(new_message, user.id, locale.replies.not_in_cache)
          history.delete_message_group(new_message)
          return
        end
      end

      # TODO: Add R9K write hook

      user.set_active
      database.update_user(user)
      
      if user.debug_enabled
        receivers = database.get_active_users
      else
        receivers = database.get_active_users(user.id)
      end

      relay.send_animation(
        new_message,
        user,
        receivers,
        reply_msids,
        animation.file_id,
        caption,
        entities,
        @allow_spoilers ? message.has_media_spoiler? : false,
      )
    end
  end
end