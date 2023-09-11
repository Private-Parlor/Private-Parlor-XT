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

    def format_time(time : Time?, format : String) : String?
      if time
        time.to_s(format)
      end
    end
  end
end
