require "../../command_handler.cr"
require "../../services.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "ranksay", config: "enable_ranksay")]
  # Processes ranksay messages before the update handler gets them
  # This handler expects the command handlers to be registered before the update handlers
  class RanksayCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = get_user_from_message(message, services)

      return if message.forward_origin

      return unless authority = authorized?(
                      user,
                      message,
                      services,
                      :Ranksay, :RanksayLower
                    )

      text, entities = Format.valid_text_and_entities(message, user, services)
      return unless text

      unless arg = Format.get_arg(text)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
      end

      return if spamming?(user, message, arg, services)

      return unless rank_name = get_rank_name(text, user, message, authority, services)

      return unless Robot9000.checks(user, message, services, arg)

      text, entities = Format.format_text(text, entities, false, services)

      entities = update_entities(text, entities, arg)

      text, entities = Format.format_ranksay(rank_name, arg, entities)

      if message.text
        message.text = text
        message.entities = entities
      elsif message.caption
        message.caption = text
        message.caption_entities = entities
      end

      message.preformatted = true

      services.relay.log_output(
        Format.substitute_message(services.logs.ranked_message, {
          "id"   => user.id.to_s,
          "name" => user.get_formatted_name,
          "rank" => rank_name,
          "text" => arg,
        })
      )
    end

    def spamming?(user : User, message : Tourmaline::Message, arg : String, services : Services) : Bool
      return false unless spam = services.spam

      if message.text && spam.spammy_text?(user.id, arg)
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.spamming)
        return true
      end

      false
    end

    def get_rank_name(text : String, user : User, message : Tourmaline::Message, authority : CommandPermissions, services : Services) : String?
      return unless rank = text.match(/^\/(.+?)say\s/).try(&.[1])

      if rank == "rank"
        parsed_rank = services.access.find_rank(rank, user.rank)
      else
        parsed_rank = services.access.find_rank(rank)
      end

      unless parsed_rank
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      parsed_rank_authority = services.access.authorized?(parsed_rank[0], :Ranksay, :RanksayLower)

      unless services.access.can_ranksay?(parsed_rank[0], user.rank, authority, parsed_rank_authority)
        return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.fail)
      end

      parsed_rank[1].name
    end

    def authorized?(user : User, message : Tourmaline::Message, services : Services, *permissions : CommandPermissions) : CommandPermissions?
      if authority = services.access.authorized?(user.rank, *permissions)
        authority
      else
        services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.command_disabled)
      end
    end
  end
end
