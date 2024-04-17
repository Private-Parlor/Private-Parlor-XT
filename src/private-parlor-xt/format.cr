require "digest"
require "tourmaline"

module PrivateParlorXT
  module Format
    include Tourmaline::Helpers
    extend self

    @[Link("crypt")]
    lib LibCrypt
      fun crypt(password : UInt8*, salt : UInt8*) : UInt8*
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
        escape_md(variables[match[1..-2]]?, version: 2)
      end
    end

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

    def format_text(text : String, entities : Array(Tourmaline::MessageEntity), preformatted : Bool?, services : Services) : Tuple(String, Array(Tourmaline::MessageEntity))
      unless preformatted
        text, entities = Format.strip_format(text, entities, services.config.entity_types, services.config.linked_network)
      end

      return text, entities
    end

    def get_text_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String?, Array(Tourmaline::MessageEntity))
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

    def valid_text_and_entities(message : Tourmaline::Message, user : User, services : Services) : Tuple(String?, Array(Tourmaline::MessageEntity))
      text = message.caption || message.text || ""
      entities = message.entities.empty? ? message.caption_entities : message.entities

      unless check_text(text, user, message, services)
        return nil, [] of Tourmaline::MessageEntity
      end

      return text, entities
    end

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
        header, entities = Format.format_flag_sign(name, entities)
      else
        header, entities = Format.format_tripcode_sign(name, tripcode, entities)
      end

      return header + text, entities
    end

    def format_cooldown_until(expiration : Time?, locale : Locale, replies : Replies) : String
      if time = format_time(expiration, locale.time_format)
        "#{replies.cooldown_true} #{time}"
      else
        replies.cooldown_false
      end
    end

    def format_warn_expiry(expiration : Time?, locale : Locale, replies : Replies) : String?
      if time = format_time(expiration, locale.time_format)
        replies.info_warning.gsub("{warn_expiry}", "#{time}")
      end
    end

    def format_tripcode_set_reply(set_format : String, name : String, tripcode : String, replies : Replies) : String
      set_format = set_format.gsub("{name}", escape_md(name, version: 2))

      set_format = set_format.gsub("{tripcode}", escape_md(tripcode, version: 2))

      replies.tripcode_set.gsub("{set_format}", set_format)
    end

    def format_reason_reply(reason : String?, replies : Replies) : String?
      if reason
        "#{replies.reason_prefix}#{reason}"
      end
    end

    def truncate_karma_reason(reason : String?) : String?
      return unless reason

      reason[0, 500]
    end

    def format_karma_reason_reply(reason : String?, karma_reply : String, replies : Replies) : String
      return Format.substitute_reply(karma_reply) unless reason

      reason = reason.gsub(/\\+$/, "")

      return Format.substitute_reply(karma_reply) if reason.empty?

      # Remove trailing punctuation after placeholder in karma_reply
      karma_reply = karma_reply.gsub(/{karma_reason}([[:punct:]]+(?=\n|\\n))/, "{karma_reason}")

      reason = escape_md(reason, version: 2)

      reason = reason.gsub("\n", "\n>")

      karma_reply.gsub(
        "{karma_reason}",
        replies.karma_reason.gsub("{reason}", "#{reason}")
      )
    end

    def format_reason_log(reason : String?, logs : Logs) : String?
      if reason
        "#{logs.reason_prefix}#{reason}"
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

    # Returns arguments found after a command from a message text.
    def get_arg(text : String?) : String | Nil
      return unless text

      text.split(2)[1]?
    end

    def get_args(text : String?, count : Int) : Array(String) | Nil
      return unless text

      text.split(count + 1)[1..]?
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
      unless origin = message.forward_origin
        return nil, [] of Tourmaline::MessageEntity
      end

      if origin.is_a?(Tourmaline::MessageOriginUser)
        if origin.sender_user.is_bot?
          Format.format_username_forward(origin.sender_user.full_name, origin.sender_user.username, entities)
        else
          Format.format_user_forward(origin.sender_user.full_name, origin.sender_user.id, entities)
        end
      elsif origin.is_a?(Tourmaline::MessageOriginChannel)
        if origin.chat.username
          Format.format_username_forward(origin.chat.name, origin.chat.username, entities, origin.message_id)
        else
          Format.format_private_channel_forward(origin.chat.name, origin.chat.id, entities, origin.message_id)
        end
      elsif origin.is_a?(Tourmaline::MessageOriginHiddenUser)
        Format.format_private_user_forward(origin.sender_user_name, entities)
      else
        return nil, [] of Tourmaline::MessageEntity
      end
    end

    # Returns a link to a given user's account, for reveal messages
    def format_user_reveal(id : UserID, name : String, replies : Replies) : String
      replies.username_reveal.gsub("{username}", "[#{escape_md(name, version: 2)}](tg://user?id=#{id})")
    end

    def format_user_forward(name : String, id : Int64 | Int32, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header_size),
        Tourmaline::MessageEntity.new("text_link", 15, name_size, "tg://user?id=#{id}"),
      ].concat(entities)

      return header, entities
    end

    def format_private_user_forward(name : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header_size),
        Tourmaline::MessageEntity.new("italic", 15, name_size),
      ].concat(entities)

      return header, entities
    end

    # For bots or public channels
    def format_username_forward(name : String, username : String?, entities : Array(Tourmaline::MessageEntity), msid : Int64 | Int32 | Nil = nil) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header_size),
        Tourmaline::MessageEntity.new("text_link", 15, name_size, "tg://resolve?domain=#{username}#{"&post=#{msid}" if msid}"),
      ].concat(entities)

      return header, entities
    end

    # Removes the "-100" prefix for private channels
    def format_private_channel_forward(name : String, id : Int64 | Int32, entities : Array(Tourmaline::MessageEntity), msid : Int64 | Int32 | Nil = nil) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "Forwarded from #{name}\n\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("bold", 0, header_size),
        Tourmaline::MessageEntity.new("text_link", 15, name_size, "tg://privatepost?channel=#{id.to_s[4..]}#{"&post=#{msid}" if msid}"),
      ].concat(entities)

      return header, entities
    end

    def format_user_sign(name : String, id : UserID, arg : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      signature = "~~#{name}"

      signature_size = signature.to_utf16.size

      entities.concat([
        Tourmaline::MessageEntity.new(
          "text_link",
          arg.to_utf16.size + 1,
          signature_size,
          url: "tg://user?id=#{id}"
        ),
      ])

      return "#{arg} #{signature}", entities
    end

    def format_karma_sign(level : String, arg : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      signature = "t. #{level}"

      signature_size = signature.to_utf16.size

      entities.concat([
        Tourmaline::MessageEntity.new("bold", arg.to_utf16.size + 1, signature_size),
        Tourmaline::MessageEntity.new("italic", arg.to_utf16.size + 1, signature_size),
      ])

      return "#{arg} #{signature}", entities
    end

    def format_tripcode_sign(name : String, tripcode : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
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

    def format_flag_sign(name : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      header = "#{name}:\n"

      header_size = header[..-3].to_utf16.size
      name_size = name.to_utf16.size

      entities = offset_entities(entities, header_size + 2)

      entities = [
        Tourmaline::MessageEntity.new("code", 0, name_size),
      ].concat(entities)

      return header, entities
    end

    def format_ranksay(rank : String, arg : String, entities : Array(Tourmaline::MessageEntity)) : Tuple(String, Array(Tourmaline::MessageEntity))
      signature = "~~#{rank}"

      signature_size = signature.to_utf16.size

      entities.concat([
        Tourmaline::MessageEntity.new("bold", arg.to_utf16.size + 1, signature_size),
      ])

      return "#{arg} #{signature}", entities
    end

    def offset_entities(entities : Array(Tourmaline::MessageEntity), offset : Int32) : Array(Tourmaline::MessageEntity)
      entities.each do |entity|
        entity.offset += offset
      end

      entities
    end

    def reset_entities(entities : Array(Tourmaline::MessageEntity), amount : Int32) : Array(Tourmaline::MessageEntity)
      entities.each do |entity|
        entity.offset -= amount
      end

      entities
    end

    def format_contact_reply(contact : String?, replies : Replies) : String?
      if contact
        replies.blacklist_contact.gsub("{contact}", contact)
      end
    end

    def format_time_span(time : Time::Span, locale : Locale) : String
      case
      when time < 1.minute then "#{time.to_i}#{locale.time_units[4]}"
      when time < 1.hour   then "#{time.total_minutes.floor.to_i}#{locale.time_units[3]}"
      when time < 1.day    then "#{time.total_hours.floor.to_i}#{locale.time_units[2]}"
      when time < 1.week   then "#{time.total_days.floor.to_i}#{locale.time_units[1]}"
      else                      "#{time.total_weeks.floor.to_i}#{locale.time_units[0]}"
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

    # Formats a loading bar for the /karmainfo command
    def format_karma_loading_bar(percentage : Float32, locale : Locale) : String
      pips = (percentage.floor.to_i).divmod(10)

      if pips[0] != 10
        String.build(10) do |str|
          str << locale.loading_bar[2] * pips[0]

          if pips[1] >= 5
            str << locale.loading_bar[1]
          else
            str << locale.loading_bar[0]
          end

          str << locale.loading_bar[0] * (10 - (pips[0] + 1))
        end
      else
        locale.loading_bar[2] * 10
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
      "Private Parlor XT v#{escape_md(VERSION, version: 2)} \\~ [\\[Source\\]](https://github.com/Private-Parlor/Private-Parlor-XT)"
    end

    # Returns a message containing the commands the user can use.
    def format_help(user : User, ranks : Hash(Int32, Rank), descriptions : CommandDescriptions, replies : Replies) : String
      ranked = {
        CommandPermissions::Promote      => "/promote [name/OID/ID] [rank] - #{descriptions.promote}",
        CommandPermissions::PromoteSame  => "/promote [name/OID/ID] [rank] - #{descriptions.promote}",
        CommandPermissions::PromoteLower => "/promote [name/OID/ID] [rank] - #{descriptions.promote}",
        CommandPermissions::Demote       => "/demote [name/OID/ID] [rank] - #{descriptions.demote}",
        CommandPermissions::Ranksay      => "/#{ranks[user.rank].name.downcase}say [text] - #{descriptions.ranksay}",
        CommandPermissions::Sign         => "/sign [text] - #{descriptions.sign}",
        CommandPermissions::TSign        => "/tsign [text] - #{descriptions.tsign}",
        CommandPermissions::Uncooldown   => "/uncooldown [name/OID] - #{descriptions.uncooldown}",
        CommandPermissions::Whitelist    => "/whitelist [ID] - #{descriptions.whitelist}",
        CommandPermissions::Purge        => "/purge - #{descriptions.purge}",
        CommandPermissions::MotdSet      => "/motd - #{descriptions.motd_set}",
      }

      reply_required = {
        CommandPermissions::Upvote     => "+1 - #{descriptions.upvote}",
        CommandPermissions::Downvote   => "-1 - #{descriptions.downvote}",
        CommandPermissions::Warn       => "/warn [reason] - #{descriptions.warn}",
        CommandPermissions::Delete     => "/delete [reason] - #{descriptions.delete}",
        CommandPermissions::Spoiler    => "/spoiler - #{descriptions.spoiler}",
        CommandPermissions::Remove     => "/remove [reason] - #{descriptions.remove}",
        CommandPermissions::Blacklist  => "/blacklist [reason] - #{descriptions.blacklist}",
        CommandPermissions::RankedInfo => "/info - #{descriptions.ranked_info}",
        CommandPermissions::Reveal     => "/reveal - #{descriptions.reveal}",
        CommandPermissions::Pin        => "/pin - #{descriptions.pin}",
        CommandPermissions::Unpin      => "/unpin - #{descriptions.unpin}",
      }

      String.build do |str|
        str << replies.help_header
        str << "\n"
        str << escape_md("/start - #{descriptions.start}\n", version: 2)
        str << escape_md("/stop - #{descriptions.stop}\n", version: 2)
        str << escape_md("/info - #{descriptions.info}\n", version: 2)
        str << escape_md("/users - #{descriptions.users}\n", version: 2)
        str << escape_md("/version - #{descriptions.version}\n", version: 2)
        str << escape_md("/toggle_karma - #{descriptions.toggle_karma}\n", version: 2)
        str << escape_md("/toggle_debug - #{descriptions.toggle_debug}\n", version: 2)
        str << escape_md("/tripcode - #{descriptions.tripcode}\n", version: 2)
        str << escape_md("/motd - #{descriptions.motd}\n", version: 2)
        str << escape_md("/help - #{descriptions.help}\n", version: 2)

        rank_commands = [] of String
        reply_commands = [] of String

        if rank = ranks[user.rank]?
          if rank.command_permissions.includes?(:ranksay_lower)
            ranks.each do |k, v|
              if k <= user.rank && k != -10 && v.command_permissions.includes?(:ranksay)
                rank_commands << escape_md("/#{v.name.downcase}say [text] - #{descriptions.ranksay}\n", version: 2)
              end
            end
          end

          rank.command_permissions.each do |permission|
            if ranked.keys.includes?(permission)
              rank_commands << escape_md(ranked[permission], version: 2)
            elsif reply_required.keys.includes?(permission)
              reply_commands << escape_md(reply_required[permission], version: 2)
            end
          end

          unless rank_commands.empty?
            str << "\n"
            str << substitute_reply(replies.help_rank_commands, {"rank" => rank.name})
            str << "\n"
            rank_commands.each { |line| str << "#{line}\n" }
          end
          unless reply_commands.empty?
            str << "\n"
            str << replies.help_reply_commands
            str << "\n"
            reply_commands.each { |line| str << "#{line}\n" }
          end
        end
      end
    end
  end
end
