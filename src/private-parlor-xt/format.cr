require "tourmaline"

module PrivateParlorXT
  module Format
    include Tourmaline::Helpers
    extend self

    # Globally substitutes placeholders in message with the given variables
    def substitute_message(msg : String, locale : Locale, variables : Hash(String, String?) = {"" => ""}) : String
      msg.gsub(/{\w+}/) do |match|
        escape_html(variables[match[1..-2]])
      end
    end

    def format_cooldown_until(expiration : Time?, locale : Locale) : String
      if time = format_time(expiration, locale.time_format)
        "#{locale.replies.cooldown_true} #{time}"
      else
        locale.replies.cooldown_false
      end
    end

    def format_warn_expiry(expiration : Time?, locale : Locale) : String?
      if time = format_time(expiration, locale.time_format)
        locale.replies.info_warning.gsub("{warn_expiry}", "#{time}")
      end
    end

    def strip_format(text : String, entities : Array(Tourmaline::MessageEntity), strip_types : Array(String), linked_network : Hash(String, String)) : Tuple(String, Array(Tourmaline::MessageEntity))
      formatted_text = replace_links(text, entities)

      valid_entities = remove_entities(entities, strip_types)

      valid_entities = format_network_links(formatted_text, valid_entities, linked_network)

      return formatted_text, valid_entities
    end

    def remove_entities(entities : Array(Tourmaline::MessageEntity), strip_types : Array(String)) : Array(Tourmaline::MessageEntity)
      stripped_entities = [] of Tourmaline::MessageEntity

      entities.each do |entity|
        if strip_types.includes?(entity.type)
          stripped_entities << entity
        end
      end

      entities - stripped_entities
    end

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

    def format_network_links(text : String, entities : Array(Tourmaline::MessageEntity), linked_network : Hash(String, String)) : Array(Tourmaline::MessageEntity)
      offset = 0

      while (start_index = text.index(/>>>\/\w+\//, offset)) && start_index != nil
        chat_string_index = start_index + 4

        next unless end_index = text.index('/', chat_string_index)

        next unless chat = linked_network[text[chat_string_index...end_index]]?

        entities << Tourmaline::MessageEntity.new(
          "text_link",
          start_index,
          (end_index - start_index) + 1, # Include the last forward slash in the text highlight
          "tg://resolve?domain=#{chat}"
        )

        offset = end_index
      end

      entities
    end

    # Checks the content of the message text and determines if it should be relayed.
    #
    # Returns false if the text has mathematical alphanumeric symbols, as they contain bold and italic characters.
    def allow_text?(text : String) : Bool
      if text.empty?
        true
      elsif text.codepoints.any? { |codepoint| (0x1D400..0x1D7FF).includes?(codepoint) }
        false
      else
        true
      end
    end

    # Checks the text and entities for a forwarded message to determine if it
    # was relayed as a regular message
    #
    # Returns true if the forward message was relayed regularly, nil otherwise
    def regular_forward?(text : String?, entities : Array(Tourmaline::MessageEntity)) : Bool?
      return unless text
      if ent = entities.first?
        text.starts_with?("Forwarded from") && ent.type == "bold"
      end
    end

    def get_forward_header(message : Tourmaline::Message, entities : Array(Tourmaline::MessageEntity)) : Tuple(String?, Array(Tourmaline::MessageEntity))
      if from = message.forward_from
        if from.is_bot?
          Format.format_username_forward(from.full_name, from.username, entities)
        elsif from.id
          Format.format_user_forward(from.full_name, from.id, entities)
        else
          return nil, [] of Tourmaline::MessageEntity
        end
      elsif (from = message.forward_from_chat) && message.forward_from_message_id
        if from.username
          Format.format_username_forward(from.name, from.username, entities, message.forward_from_message_id)
        else
          Format.format_private_channel_forward(from.name, from.id, entities, message.forward_from_message_id)
        end
      elsif from = message.forward_sender_name
        Format.format_private_user_forward(from, entities)
      else
        return nil, [] of Tourmaline::MessageEntity
      end
    end

    def format_user_forward(name : String, id : Int64 | Int32, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"
      entities = offset_entities(entities, header.size)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header.size),
        Tourmaline::MessageEntity.new("text_link", 15, name.size, "tg://user?id=#{id}")
      ].concat(entities)

      return header, entities
    end
  
    def format_private_user_forward(name : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"
      entities = offset_entities(entities, header.size)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header.size),
        Tourmaline::MessageEntity.new("italic", 15, name.size)
      ].concat(entities)

      return header, entities
    end
  
    # For bots or public channels
    def format_username_forward(name : String, username : String?, entities : Array(Tourmaline::MessageEntity), msid : Int64 | Int32 | Nil = nil) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"
      entities = offset_entities(entities, header.size)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header.size),
        Tourmaline::MessageEntity.new("text_link", 15, name.size, "tg://resolve?domain=#{escape_html(username)}#{"&post=#{msid}" if msid}")
      ].concat(entities)

      return header, entities
    end
  
    # Removes the "-100" prefix for private channels
    def format_private_channel_forward(name : String, id : Int64 | Int32, entities : Array(Tourmaline::MessageEntity), msid : Int64 | Int32 | Nil = nil) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"
      entities = offset_entities(entities, header.size)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header.size),
        Tourmaline::MessageEntity.new("text_link", 15, name.size, "tg://privatepost?channel=#{id.to_s[4..]}#{"&post=#{msid}" if msid}")
      ].concat(entities)

      return header, entities
    end

    def offset_entities(entities : Array(Tourmaline::MessageEntity), offset : Int32) : Array(Tourmaline::MessageEntity)
      entities.each do |entity|
        entity.offset += offset
      end

      entities
    end

    def format_reason_reply(reason : String?, locale : Locale) : String?
      if reason
        "#{locale.replies.reason_prefix}#{reason}"
      end
    end

    def format_contact_reply(contact : String?, locale : Locale) : String?
      if contact
        locale.replies.blacklist_contact.gsub("{contact}", "#{escape_html(contact)}")
      end
    end

    # Returns a smiley based on the number of given warnings
    def format_smiley(warnings : Int32, smileys : Array(String)) : String
      case warnings
      when (0..0) then smileys[0]
      when (1..2) then smileys[1]
      when (2..5) then smileys[2]
      else             smileys[3]
      end
    end

    def format_time(time : Time?, format : String) : String?
      if time
        time.to_s(format)
      end
    end

    # Returns a message containing the program version and a link to its Git repo.
    #
    # Feel free to edit this if you fork the code.
    def format_version : String
      "Private Parlor v#{VERSION} ~ <a href=\"https://github.com/Private-Parlor/Private-Parlor-XT\">[Source]</a>"
    end
  end
end
