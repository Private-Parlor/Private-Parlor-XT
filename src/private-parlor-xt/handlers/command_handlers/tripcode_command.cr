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
            invalid_format = Format.substitute_reply(services.replies.invalid_tripcode_format, {
              "valid_format" => services.replies.flag_sign_format,
            })
            return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, invalid_format)
          end

          # Append with a pound sign and the user's obfuscated ID to make
          # the flag signature still compatible with tripcode generations
          tripcode = arg + '#' + user.get_obfuscated_id
          user.set_tripcode(tripcode)

          name, _ = Format.generate_tripcode(tripcode, services)

          response = Format.format_tripcode_set_reply(
            services.replies.flag_sign_set_format,
            name,
            "",
            services.replies
          )
        else
          unless valid_tripcode?(arg)
            invalid_format = Format.substitute_reply(services.replies.invalid_tripcode_format, {
              "valid_format" => services.replies.tripcode_format,
            })
            return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, invalid_format)
          end

          user.set_tripcode(arg)

          name, tripcode = Format.generate_tripcode(arg, services)

          response = Format.format_tripcode_set_reply(
            services.replies.tripcode_set_format,
            name,
            tripcode,
            services.replies
          )
        end
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
