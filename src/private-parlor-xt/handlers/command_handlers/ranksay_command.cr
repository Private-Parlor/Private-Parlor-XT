require "../../handlers.cr"
require "../../services.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "ranksay", config: "enable_ranksay")]
  # Processes ranksay messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class RanksayCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services)
      message, user = get_message_and_user(context, services)
      return unless message && user

      return if message.forward_date

      return unless authority = is_authorized?(
        user, 
        message,
        services,
        :Ranksay, :RanksayLower
      )

      return unless text = message.text || message.caption

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.missing_args) 
      end

      return if is_spamming?(user, message, arg, services)

      return unless rank_name = get_rank_name(text, user, message, authority, services)

      entities = message.entities.empty? ? message.caption_entities : message.entities

      if command_entity = entities.find { |item| item.type == "bot_command" && item.offset == 0}
        entities = entities - [command_entity]
      end

      # Remove command and all whitespace before the start of arg
      arg_offset = text[...text.index(arg)].to_utf16.size
      entities = Format.reset_entities(entities, arg_offset)

      text, entities = Format.format_ranksay(rank_name, arg, entities)

      if message.text
        message.text = text 
        message.entities = entities
      elsif message.caption
        message.caption = text
        message.caption_entities = entities
      end

      message.preformatted = true
    end

    def is_spamming?(user : User, message : Tourmaline::Message, arg : String, services : Services) : Bool
      return false unless spam = services.spam

      if message.text && spam.spammy_text?(user.id, arg)
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.spamming)
        return true
      end

      return false
    end

    def get_rank_name(text : String, user : User, message : Tourmaline::Message, authority : CommandPermissions, services : Services) : String?
      return unless rank = text.match(/^\/(.+?)say\s/).try(&.[1])

      if rank == "rank"
        parsed_rank = services.access.find_rank(rank, user.rank)
      else
        parsed_rank = services.access.find_rank(rank)
      end

      unless parsed_rank
        return services.relay.send_to_user(message.message_id.to_i64, user.id, Format.substitute_message(services.locale.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      parsed_rank_authority = services.access.authorized?(parsed_rank[0], :Ranksay, :RanksayLower)

      unless services.access.can_ranksay?(parsed_rank[0], user.rank, authority, parsed_rank_authority)
        return services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.fail)
      end

      return parsed_rank[1].name
    end

    def is_authorized?(user : User, message : Tourmaline::Message, services : Services, *permissions : CommandPermissions) : CommandPermissions?
      if authority = services.access.authorized?(user.rank, *permissions)
        authority
      else
        services.relay.send_to_user(message.message_id.to_i64, user.id, services.locale.replies.command_disabled)
      end
    end
  end
end