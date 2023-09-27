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
      entities.reverse.each do |entity|
        if entity.type == "url"
          text = text.delete_at(entity.offset, entity.length)
        end
      end

      text
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

      text = text.gsub(/[[:punct:]]|—/, "") # Remove punctuation and em-dash

      # Reduce repeating characters, excluding digits
      text = text.gsub(/(?![\d])(\w|\w{1,})\1{2,}/) do |_, match|
        match[1]
      end

      # Remove network links
      text = text.gsub(/>>>\/\w+\//, "")

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
  end
end
