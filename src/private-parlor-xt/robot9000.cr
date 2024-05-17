require "./constants.cr"

module PrivateParlorXT
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
    def media_file_id(message : Tourmaline::Message) : String?
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

    # Checks the *message* for uniqueness and returns `true` if:
    #   - Message is preformatted (message already checked)
    #   - Message is a forward, but this `Robot9000` is not configured to check forwards for uniqueness
    #   - No media file ID could be found when checking message media
    #   - Message is unique
    # 
    # Returns `false` if the message does not pass the `text_check` or the `media_check`; *message* is unoriginal
    # 
    # The unique text and/or file_id will be stored to flag future messages of the same kind as unoriginal
    def unique_message?(user : User, message : Tourmaline::Message, services : Services, text : String? = nil) : Bool
      return true if message.preformatted?
      return true if message.forward_origin && !@check_forwards

      if @check_text
        unless text
          text = message.text || message.caption || ""
        end
  
        entities = message.caption_entities.empty? ? message.entities : message.caption_entities
  
        stripped_text = strip_text(text, entities)

        return false unless unique_text = unique_text(user, message, services, stripped_text)
      end

      if @check_media
        return true unless file_id = media_file_id(message)

        return false unless unique_media = unique_media(user, message, services, file_id)
      end

      if unique_text
        add_line(unique_text)
      end

      if unique_media
        add_file_id(unique_media)
      end

      true
    end

    # Returns the *text* if the *message*'s text or caption is unique
    # 
    # Returns `nil` if the *message*'s text or caption is not unique, and cooldowns the sender if configured to do so
    def unique_text(user : User, message : Tourmaline::Message, services : Services, text : String) : String?
      if unoriginal_text?(text)
        if stats = services.stats
          stats.increment_unoriginal_text
        end

        return unoriginal_message(user, message, services)
      end

     text
    end

    # Returns the *file_id* if the *message*'s media is unique
    # 
    # Returns `nil` if the *message*'s media is not unique, and cooldowns the sender if configured to do so
    def unique_media(user : User, message : Tourmaline::Message, services : Services, file_id : String) : String?
      if unoriginal_media?(file_id)
        if stats = services.stats
          stats.increment_unoriginal_media
        end

        return unoriginal_message(user, message, services)
      end

      file_id
    end

    # Queues a message telling the *user* that the *message* was unoriginal, and cooldowns the *user* if configured to do so
    def unoriginal_message(user : User, message : Tourmaline::Message, services : Services) : Nil
      if @cooldown > 0
        duration = user.cooldown(@cooldown.seconds)
        services.database.update_user(user)

        response = Format.substitute_reply(services.replies.r9k_cooldown, {
          "duration" => Format.time_span(duration, services.locale),
        })
      elsif @warn_user
        duration = user.cooldown(services.config.cooldown_base)
        user.warn(services.config.warn_lifespan)
        services.database.update_user(user)

        response = Format.substitute_reply(services.replies.r9k_cooldown, {
          "duration" => Format.time_span(duration, services.locale),
        })
      else
        response = services.replies.unoriginal_message
      end

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end
  end
end
