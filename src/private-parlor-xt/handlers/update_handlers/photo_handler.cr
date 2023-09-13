require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[On(update: :Photo, config: "relay_photo")]
  class PhotoHandler < UpdateHandler
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

      unless access.authorized?(user.rank, :Photo)
        response = Format.substitute_message(locale.replies.media_disabled, locale, {"type" => "text"})
        return relay.send_to_user(message.message_id.to_i64, user.id, response)
      end

      return if message.forward_date
      return if message.media_group_id

      if spam && spam.spammy_photo?(user.id)
        return relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.spamming)
      end

      photo = message.photo.last

      caption = message.caption || ""

      # TODO: Add R9K check hook

      caption, entities = check_text(caption, user, message, relay, locale)

      # TODO: Add pseudonymous hook

      # TODO: Add R9K write hook

      user.set_active
      database.update_user(user)

      if reply = message.reply_to_message
        reply = reply.message_id.to_i64
      else
        reply = nil
      end

      relay.send_photo(
        reply,
        user,
        history.new_message(user.id, message.message_id.to_i64),
        photo.file_id,
        caption,
        entities,
        @allow_spoilers ? message.has_media_spoiler? : false,
        locale,
        history,
        database,
      )
    end
  end
end