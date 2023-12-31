require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["tripcode", "signature"], config: "enable_tripcode")]
  class TripcodeCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      if arg = Format.get_arg(message.text)
        if services.config.flag_signatures
          unless valid_signature?(arg)
            # TODO: Update locales
            return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.invalid_tripcode_format)
          end

          # Append with a pound sign and the user's obfuscated ID to make
          # the flag signature still compatible with tripcode generations
          user.set_tripcode(arg + '#' + user.get_obfuscated_id)
        else
          unless valid_tripcode?(arg)
            return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.invalid_tripcode_format)
          end

          user.set_tripcode(arg)
        end

        name, tripcode = Format.generate_tripcode(arg, services)

        response = Format.substitute_reply(services.replies.tripcode_set, {
          "name"     => name,
          "tripcode" => tripcode,
        })
      else
        response = Format.substitute_reply(services.replies.tripcode_info, {
          "tripcode" => user.tripcode ? user.tripcode : services.replies.tripcode_unset,
        })
      end

      update_user_activity(user, services)

      services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, response)
    end

    def valid_tripcode?(arg : String) : Bool
      return false unless pound_index = arg.index('#')

      return false if pound_index == arg.size - 1

      return false if arg.size > 30

      return false if arg.includes?("\n")

      true
    end

    def valid_signature?(arg : String) : Bool?
      return false if arg.graphemes.size > 5
      return false if arg.includes?("\n")

      emoji_ranges = [
        (0x2600..0x26ff),   # Misc Symbols
        (0xE0000..0xE007F), # Formatting Tag Characters
        (0x1FA70..0x1FAFF), # Symbols and Pictographs Extended-A
        (0x1F900..0x1F9FF), # Supplemental Symbols and Pictographs
        (0x1F300..0x1F5FF), # Miscellaneous Symbols and Pictographs
        (0x1F600..0x1F64F), # Emoticons
        (0x1F1E6..0x1F1FF), # Regional Indicators
        (0xFE0F..0xFE0F),   # Colorized Emoji Variant Selector
        (0x200D..0x200D),   # Zero-width Joiner
      ]

      return false if arg.codepoints.any? do |codepoint|
                        emoji_ranges.none? do |range|
                          range.includes?(codepoint)
                        end
                      end

      true
    end
  end
end
