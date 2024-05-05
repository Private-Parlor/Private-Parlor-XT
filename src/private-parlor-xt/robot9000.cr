require "./constants.cr"

module PrivateParlorXT

  # TODO: Remove class methods and move cooldown functionality to its own function

  # A base class for ROBOT9000 implementations
  # 
  # ROBOT9000 is an algorithm by Randall Munroe designed to reduce noise in large chats and
  # encourage original content.
  #
  # ROBOT9000 will prevent users from repeating information that has already been posted before. 
  # When a user's post is considered unoriginal, the post will not be sent and the user will be cooldowned.
  # 
  # Subclasses of this type should use a `Database` to store and query unique texts and media IDs
  abstract class Robot9000
    # An array of Int32 ranges corresponding to Unicode codeblock ranges to accept.
    # 
    # When checking texts for uniqueness, each characater/codepoint must be found within these ranges.
    # 
    # Default accepts codepoints in the ASCII character set
    @valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)]

    # Returns `true` if this module should check text for uniqueness
    # 
    # Returns `false` otherwise
    getter? check_text : Bool? = false

    # Returns `true` if this module should check media (photos, audio, videos, etc.) for uniqueness
    # 
    # Returns `false` otherwise
    getter? check_media : Bool? = false

    # Returns `true` if this module should check forwards for uniqueness
    # 
    # If true, this module should also check for unique text or media if `check_text` or `check_media` is toggled, respectively.
    # 
    # Returns `false` otherwise
    getter? check_forwards : Bool? = false

    # Returns `true` if this module should give the user a warning for unoriginal messages
    # 
    # If true, the unoriginal message cooldown should scale with user warnings
    # 
    # Returns `false` otherwise
    getter? warn_user : Bool? = false

    # Returns the cooldown duration for unoriginal messages
    getter cooldown : Int32 = 0

    # Returns a `String` containing the given *text* with URLs removed
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

    # Returns `true` if the given *text* has valid codepoints or is empty
    # 
    # Returns `false` if any character/codepoint in the given *text* is not found in `valid_codepoints`
    def allow_text?(text : String) : Bool
      return true if text.empty?

      return false if text.codepoints.any? do |codepoint|
                        @valid_codepoints.none? do |range|
                          range.includes?(codepoint)
                        end
                      end

      true
    end

    # Returns a `String` containing the given *text* in lower case with the following elements removed:
    #   - Links/URLS
    #   - Commands
    #   - Usernames
    #   - Sequences of 3 or more repeating characters (digits can repeat)
    #   - Network links/Back links (i.e., ">>>/foo/")
    #   - Punctuation and the em-dash
    #   - Repeating spaces and newlines
    #   - Trailing and leading whitespace
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

    # Returns a `String` containing the unique file ID from the given *message*
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

    # Returns `true` if the given text has been sent before
    # Returns `false` otherwise
    abstract def unoriginal_text?(text : String) : Bool?

    # Stores the stripped line of *text* to be referenced later
    abstract def add_line(text : String) : Nil

    # Returns `true` if the given file id has been sent before
    # Returns `false` otherwise
    abstract def unoriginal_media?(id : String) : Bool?

    # Stores the file *id* to be referenced later
    abstract def add_file_id(id : String) : Nil

    # Checks the message for uniqueness and returns `true` if the message is preformatted (message already checked) or if it passes the checks
    # 
    # Returns `false` if the message does not pass the `text_check` or the `media_check`
    def self.checks(user : User, message : Tourmaline::Message, services : Services, text : String? = nil) : Bool
      return true if message.preformatted?

      return false unless text_check(user, message, services, text)
      return false unless media_check(user, message, services)

      true
    end

    # Checks the forwarded message for uniqueness and returns `true` if:
    #   - Services does not have a `Robot9000` object
    #   - This module does not check forwards for uniqueness
    #   - Forward passes `text_check` and `media_check`
    # 
    # Returns `false` if the message does not pass the `text_check` or the `media_check`
    def self.forward_checks(user : User, message : Tourmaline::Message, services : Services) : Bool
      return true unless r9k = services.robot9000
      return true unless r9k.check_forwards?

      return false unless text_check(user, message, services)
      return false unless media_check(user, message, services)

      true
    end

    # Returns `true` if the *message*'s text or caption is unique, and stores the text/caption for later
    # 
    # Returns `false` if the *message`'s text or caption is not unique, and cooldowns the sender if configured to do so
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

        if stats = services.stats
          stats.increment_unoriginal_text_count
        end

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)

        return false
      end

      r9k.add_line(stripped_text)

      true
    end

    # Returns `true` if the *message*'s media is unique, and stores its file ID for later
    # 
    # Returns `false` if the *message`'s media is not unique, and cooldowns the sender if configured to do so
    def self.media_check(user : User, message : Tourmaline::Message, services : Services) : Bool
      unless (r9k = services.robot9000) && r9k.check_media?
        return true
      end
      
      return true unless file_id = r9k.get_media_file_id(message)

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

        if stats = services.stats
          stats.increment_unoriginal_media_count
        end

        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)

        return false
      end

      r9k.add_file_id(file_id)

      true
    end
  end
end
