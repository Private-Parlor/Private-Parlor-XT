require "./constants.cr"

module PrivateParlorXT
  abstract class Robot9000
    @valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)]

    getter? check_text : Bool? = false
    getter? check_media : Bool? = false
    getter? check_forwards : Bool? = false
    getter? warn_user : Bool? = false
    getter cooldown : Int32 = 0

    def remove_links(text : String, entities : Array(Tourmaline::MessageEntity)) : String
      string = text.to_utf16.to_a

      entities.reverse.each do |entity|
        if entity.type == "url"
          string.delete_at(entity.offset, entity.length)
        end
      end

      utf = Slice(UInt16).new(string.size) { |i| string[i] }

      String.from_utf16(utf)
    end

    def allow_text?(text : String) : Bool
      return true if text.empty?

      return false if text.codepoints.any? do |codepoint|
                        @valid_codepoints.none? do |range|
                          range.includes?(codepoint)
                        end
                      end

      true
    end

    def strip_text(text : String, entities : Array(Tourmaline::MessageEntity)) : String
      text = remove_links(text, entities)

      text = text.downcase

      text = text.gsub(/\/\w+\s/, "") # Remove commands

      text = text.gsub(/\s@\w+\s/, " ") # Remove usernames; leave a space

      # Reduce repeating characters, excluding digits
      text = text.gsub(/(?![\d])(\w|\w{1,})\1{2,}/) do |_, match|
        match[1]
      end

      # Remove network links
      text = text.gsub(/>>>\/\w+\//, "")

      text = text.gsub(/[[:punct:]]|—/, "") # Remove punctuation and em-dash

      # Remove repeating spaces and new lines; leave a space
      text = text.gsub(/\s{2,}|\n/, " ")

      # Remove trailing and leading whitespace
      text.strip
    end

    def get_media_file_id(message : Tourmaline::Message) : String?
      if media = message.animation
      elsif media = message.audio
      elsif media = message.document
      elsif media = message.video
      elsif media = message.video_note
      elsif media = message.voice
      elsif media = message.photo.last?
      elsif media = message.sticker
      else
        return
      end

      media.file_unique_id
    end

    # Returns true if the given text has been sent before
    # Returns false otherwise
    abstract def unoriginal_text?(text : String) : Bool?

    # Stores the stripped line of text to be referenced later
    abstract def add_line(text : String) : Nil

    # Returns ture if the given file id has been sent before
    # Returns false otherwise
    abstract def unoriginal_media?(id : String) : Bool?

    # Stores the file id to be referenced later
    abstract def add_file_id(id : String) : Nil

    def self.checks(user : User, message : Tourmaline::Message, services : Services, text : String? = nil) : Bool
      return true if message.preformatted?

      return false unless text_check(user, message, services, text)
      return false unless media_check(user, message, services)

      true
    end

    def self.forward_checks(user : User, message : Tourmaline::Message, services : Services) : Bool
      return true unless r9k = services.robot9000
      return true unless r9k.check_forwards?

      return false unless text_check(user, message, services)
      return false unless media_check(user, message, services)

      true
    end

    def self.text_check(user : User, message : Tourmaline::Message, services : Services, text : String? = nil) : Bool
      unless (r9k = services.robot9000) && r9k.check_text?
        return true
      end

      unless text
        text = message.text || message.caption || ""
      end

      entities = message.caption_entities.empty? ? message.entities : message.caption_entities

      stripped_text = r9k.strip_text(text, entities)

      if r9k.unoriginal_text?(stripped_text)
        if r9k.cooldown > 0
          duration = user.cooldown(r9k.cooldown.seconds)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        elsif r9k.warn_user?
          duration = user.cooldown(services.config.cooldown_base)
          user.warn(services.config.warn_lifespan)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        else
          response = services.replies.unoriginal_message
        end

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)

        return false
      end

      r9k.add_line(stripped_text)

      true
    end

    def self.media_check(user : User, message : Tourmaline::Message, services : Services) : Bool
      unless (r9k = services.robot9000) && r9k.check_media?
        return true
      end

      return false unless file_id = r9k.get_media_file_id(message)

      if r9k.unoriginal_media?(file_id)
        if r9k.cooldown > 0
          duration = user.cooldown(r9k.cooldown.seconds)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        elsif r9k.warn_user?
          duration = user.cooldown(services.config.cooldown_base)
          user.warn(services.config.warn_lifespan)
          services.database.update_user(user)

          response = Format.substitute_reply(services.replies.r9k_cooldown, {
            "duration" => Format.format_time_span(duration, services.locale),
          })
        else
          response = services.replies.unoriginal_message
        end

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)

        return false
      end

      r9k.add_file_id(file_id)

      true
    end
  end
end
