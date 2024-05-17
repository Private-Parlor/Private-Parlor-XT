require "digest"
require "tourmaline"

module PrivateParlorXT
  # A general use module for formatting text and `Tourmaline::MessageEntity`
  module Format
    include Tourmaline::Helpers
    extend self

    @[Link("crypt")]
    lib LibCrypt
      fun crypt(password : UInt8*, salt : UInt8*) : UInt8*
    end

    # A simple wrapper for `Tourmaline::Helpers.escape_md` that defaults to escaping *text* according to Telegram's MarkdownV2
    def escape_mdv2(text : String?)
      String
      escape_md(text, version: 2)
    end

    # Globally substitutes placeholders in message with the given variables
    def substitute_message(msg : String, variables : Hash(String, String?) = {"" => ""}) : String
      msg.gsub(/{\w+}/) do |match|
        variables[match[1..-2]]?
      end
    end

    # Globally substitutes placeholders in reply with the given variables
    # Excapes placeholders according to MarkdownV2
    def substitute_reply(msg : String, variables : Hash(String, String?) = {"" => ""}) : String
      msg.gsub(/{\w+}/) do |match|
        escape_mdv2(variables[match[1..-2]]?)
      end
    end

    # Checks the given *text* for invalid characters
    def check_text(text : String, user : User, message : Tourmaline::Message, services : Services) : Bool
      return true if message.preformatted?

      if r9k = services.robot9000
        unless r9k.allow_text?(text)
          services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.rejected_message)
          return false
        end
      else
        unless Format.allow_text?(text)
          services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.rejected_message)
          return false
        end
      end

      true
    end

    # Removes formatting from the given *text* and *entities*
    def format_text(text : String, entities : Array(Tourmaline::MessageEntity), preformatted : Bool?, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      unless preformatted
        text, entities = Format.strip_format(text, entities, services.config.entity_types, services.config.linked_network)
      end

      return text, entities
    end

    # Gets the text and message entities from a given *message*
    def text_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String?, Array(Tourmaline::MessageEntity))
      text = message.caption || message.text || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      if message.preformatted?
        return text, entities
      end

      unless check_text(text, user, message, services)
        return nil, [] of Tourmaline::MessageEntity
      end

      text, entities = format_text(text, message.entities, message.preformatted?, services)

      text, entities = prepend_pseudonym(text, entities, user, message, services)

      return text, entities
    end

    # Checks the text and entities from the given *message* for validity.
    #
    # Used for signature commands where the text should not be formatted or given a tripcode header if pseudonymous mode is enabled
    def validate_text_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String?, Array(Tourmaline::MessageEntity))
      text = message.caption || message.text || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      unless check_text(text, user, message, services)
        return nil, [] of Tourmaline::MessageEntity
      end

      return text, entities
    end

    # Prepend the user's tripcode to the message
    def prepend_pseudonym(text : String, entities : Array(Tourmaline::MessageEntity), user : User, message : Tourmaline::Message, services : Services) : Tuple(String?, Array(Tourmaline::MessageEntity))
      unless services.config.pseudonymous
        return text, entities
      end

      if message.preformatted?
        return text, entities
      end

      unless tripcode = user.tripcode
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.no_tripcode_set)
        return nil, [] of Tourmaline::MessageEntity
      end

      name, tripcode = Format.generate_tripcode(tripcode, services)

      if services.config.flag_signatures
        header, entities = Format.flag_sign(name, entities)
      else
        header, entities = Format.tripcode_sign(name, tripcode, entities)
      end

      return header + text, entities
    end

    # Format the *reason* for system message replies
    def reason(reason : String?, replies : Replies) : String?
      if reason
        "#{replies.reason_prefix}#{reason}"
      end
    end

    # Format the *reason* for log messages
    def reason_log(reason : String?, logs : Logs) : String?
      if reason
        "#{logs.reason_prefix}#{reason}"
      end
    end

    # Resturns text and message entities with formatting stripped, such as text_links and stripped entities, and formats network links
    def strip_format(text : String, entities : Array(Tourmaline::MessageEntity), strip_types : Array(String), linked_network : Hash(String, String)) : Tuple(String, Array(Tourmaline::MessageEntity))
      formatted_text = replace_links(text, entities)

      valid_entities = remove_entities(entities, strip_types)

      valid_entities = update_network_links(formatted_text, valid_entities, linked_network)

      return formatted_text, valid_entities
    end

    # Removes message *entities* if their types are found in *strip_types*
    def remove_entities(entities : Array(Tourmaline::MessageEntity), strip_types : Array(String)) : Array(Tourmaline::MessageEntity)
      stripped_entities = [] of Tourmaline::MessageEntity

      entities.each do |entity|
        if strip_types.includes?(entity.type)
          stripped_entities << entity
        end
      end

      entities - stripped_entities
    end

    # Generate a 2channel or secure 8chan style tripcode from a given string in the format `name#pass`.
    #
    # Returns a named tuple containing the tripname and tripcode.
    #
    # Using procedures based on code by Fredrick R. Brennan and Tinyboard Development Group
    #
    # 8chan secure tripcode:
    # Copyright (c) 2010-2014 Tinyboard Development Group
    #
    # github.com/ctrlcctrlv/infinity/blob/1535f2c976bdc503c12b5e92e605ee665e3239e7/inc/functions.php#L2755
    #
    # 2channel tripcode:
    # Copyright (c) Fredrick R. Brennan, 2020
    #
    # github.com/ctrlcctrlv/tripkeys/blob/33dcb519a8c08185aecba15eee9aa80760dddc87/doc/2ch_tripcode_annotated.pl
    def generate_tripcode(tripkey : String, services : Services) : Tuple(String, String)
      split = tripkey.split('#', 2)
      name = split[0]
      pass = split[1]

      if services.config.flag_signatures
        return {name, ""}
      end

      if !services.config.tripcode_salt.empty?
        # 8chan secure tripcode
        pass = String.new(pass.encode("Shift_JIS"), "Shift_JIS")
        trip = Digest::SHA1.base64digest(pass + services.config.tripcode_salt)

        tripcode = "!#{trip[0...10]}"
      else
        # 2channel tripcode
        character_map = {
          ':'  => 'A',
          ';'  => 'B',
          '<'  => 'C',
          '='  => 'D',
          '>'  => 'E',
          '?'  => 'F',
          '@'  => 'G',
          '['  => 'a',
          '\\' => 'b',
          ']'  => 'c',
          '^'  => 'd',
          '_'  => 'e',
          '`'  => 'f',
        }

        salt = (pass + "H.")[1, 2]
        salt = salt.gsub(/[^\.-z]/, '.')
        salt = salt.gsub(character_map)

        trip = String.new(LibCrypt.crypt(pass[...8], salt))

        tripcode = "!#{trip[-10...]}"
      end

      {name, tripcode}
    end

    # Replaces appends links contained in text link entities to the end of the given *text*
    def replace_links(text : String, entities : Array(Tourmaline::MessageEntity)) : String
      entities.each do |entity|
        if entity.type == "text_link" && (url = entity.url)
          if url.starts_with?("tg://")
            next
          end

          if url.includes?("://t.me/") && url.includes?("?start=")
            next
          end

          text += "\n(#{url})"
        end
      end
      text
    end

    # Returns a text link message entities corresponding to the network links in *text*, linking to their respective chats
    def update_network_links(text : String, entities : Array(Tourmaline::MessageEntity), linked_network : Hash(String, String)) : Array(Tourmaline::MessageEntity)
      offset = 0

      while (start_index = text.index(/>>>\/\w+\//, offset)) && start_index != nil
        chat_string_index = start_index + 4

        unless end_index = text.index('/', chat_string_index)
          offset = chat_string_index
          next
        end

        unless chat = linked_network[text[chat_string_index...end_index]]?
          offset = chat_string_index
          next
        end

        entities << Tourmaline::MessageEntity.new(
          "text_link",
          text[...start_index].to_utf16.size,
          text[start_index..end_index].to_utf16.size, # Include the last forward slash in the text highlight
          "tg://resolve?domain=#{chat}"
        )

        offset = end_index
      end

      entities
    end

    # Checks the content of the message *text* and determines if it should be relayed.
    #
    # Returns `true` if the *text* is empty or permitted, `false` if the text has mathematical alphanumeric symbols, as they contain bold and italic characters.
    def allow_text?(text : String) : Bool
      if text.empty?
        true
      elsif text.codepoints.any? { |codepoint| (0x1D400..0x1D7FF).includes?(codepoint) }
        false
      else
        true
      end
    end

    # Returns the argument following a given *text*, usually a command where the argument comes after the first whitespace
    def get_arg(text : String?) : String | Nil
      return unless text

      text.split(2)[1]?
    end

    # Returns *count* number of args after a given *text*, usually a command where the command precedes the first whitespace.
    def get_args(text : String?, count : Int) : Array(String) | Nil
      return unless text

      text.split(count + 1)[1..]?
    end

    # Format the tripcode header for tripcode signs
    def tripcode_sign(name : String, tripcode : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "#{name} #{tripcode}:\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size
      tripcode_size = tripcode.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, name_size),
        Tourmaline::MessageEntity.new("code", name_size + 1, tripcode_size),
      ].concat(entities)

      return header, entities
    end

    # Format the flag sign header for tripcode messages when flag signs are enabled
    def flag_sign(name : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "#{name}:\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("code", 0, name_size),
      ].concat(entities)

      return header, entities
    end

    # Add the given *offset* to the offset of each message entity
    def offset_entities(entities : Array(Tourmaline::MessageEntity), offset : Int32) : Array(Tourmaline::MessageEntity)
      entities.each do |entity|
        entity.offset += offset
      end

      entities
    end

    # Subtract the given *amount* from the offset of each message entity
    def reset_entities(entities : Array(Tourmaline::MessageEntity), amount : Int32) : Array(Tourmaline::MessageEntity)
      entities.each do |entity|
        entity.offset -= amount
      end

      entities
    end

    # Format the given *contact* for blacklist contact replies
    def contact(contact : String?, replies : Replies) : String?
      if contact
        replies.blacklist_contact.gsub("{contact}", contact)
      end
    end

    # Format a time span using localized time units
    def time_span(time : Time::Span, locale : Locale) : String
      case
      when time < 1.minute then "#{time.to_i}#{locale.time_units[4]}"
      when time < 1.hour   then "#{time.total_minutes.floor.to_i}#{locale.time_units[3]}"
      when time < 1.day    then "#{time.total_hours.floor.to_i}#{locale.time_units[2]}"
      when time < 1.week   then "#{time.total_days.floor.to_i}#{locale.time_units[1]}"
      else                      "#{time.total_weeks.floor.to_i}#{locale.time_units[0]}"
      end
    end

    # Formats a given `Time` based on the given *format*
    def time(time : Time?, format : String) : String?
      if time
        time.to_s(format)
      end
    end
  end
end
