require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: ["tripcode", "signature"], config: "enable_tripcode")]
  # A command used to set the user's tripcode, so that it can be used for tripcode signatures
  class TripcodeCommand < CommandHandler
    # Sets the user's tripcode or returns the user's tripcode if set when the message meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

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
          tripcode = arg + '#' + user.obfuscated_id
          user.set_tripcode(tripcode)

          name, _ = Format.generate_tripcode(tripcode, services)

          response = tripcode_set(
            services.replies.flag_sign_set_format,
            name,
            "",
            services
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

          response = tripcode_set(
            services.replies.tripcode_set_format,
            name,
            tripcode,
            services
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

    # Returns `true` if the given *arg* is a valid tripcode
    #
    # Returns false otherwise
    def valid_tripcode?(arg : String) : Bool
      return false if (count = arg.count('#')) && count == 0

      return false if count == 1 && arg.ends_with?("#")

      return false if arg.size > 30

      return false if arg.includes?("\n")

      true
    end

    # Returns `true` if the given *arg* is a valid flag signature
    #
    # Returns `false` otherwise
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

    # Format the tripcode set reply
    def tripcode_set(set_format : String, name : String, tripcode : String, services : Services) : String
      set_format = set_format.gsub("{name}", Format.escape_mdv2(name))

      set_format = set_format.gsub("{tripcode}", Format.escape_mdv2(tripcode))

      services.replies.tripcode_set.gsub("{set_format}", set_format)
    end
  end
end
