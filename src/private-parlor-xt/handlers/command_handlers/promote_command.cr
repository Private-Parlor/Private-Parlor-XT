require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "promote", config: "enable_promote")]
  class PromoteCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services)
      return unless user = get_user_from_message(message, services)

      return unless authority = authorized?(
                      user,
                      message,
                      services,
                      :Promote, :PromoteLower, :PromoteSame
                    )

      if reply = message.reply_to_message
        arg = Format.get_arg(message.text)
        promote_from_reply(
          arg,
          authority,
          user,
          message.message_id.to_i64,
          reply,
          services,
        )
      else
        unless args = Format.get_args(message.text, count: 2)
          return services.relay.send_to_user(ReplyParameters.new(message.message_id), user.id, services.replies.missing_args)
        end

        promote_from_args(
          args,
          authority,
          user,
          message.message_id.to_i64,
          services
        )
      end
    end

    def promote_from_reply(arg : String?, authority : CommandPermissions, user : User, message : MessageID, reply : Tourmaline::Message, services : Services)
      if arg
        tuple = services.access.find_rank(arg.downcase, arg.to_i?)
      else
        unless authority.in?(CommandPermissions::Promote, CommandPermissions::PromoteSame)
          return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.missing_args)
        end

        tuple = {user.rank, services.access.ranks[user.rank]}
      end

      unless tuple
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      return unless promoted_user = get_reply_user(user, reply, services)

      unless services.access.can_promote?(tuple[0], user.rank, promoted_user.rank, authority)
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      promoted_user.set_rank(tuple[0])
      services.database.update_user(promoted_user)

      services.relay.send_to_user(nil, promoted_user.id, Format.substitute_reply(services.replies.promoted, {
        "rank" => tuple[1].name,
      }))

      log = Format.substitute_message(services.logs.promoted, {
        "id"      => promoted_user.id.to_s,
        "name"    => promoted_user.get_formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.get_formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end

    def promote_from_args(args : Array(String), authority : CommandPermissions, user : User, message : MessageID, services : Services)
      if args.size == 1 && authority.in?(CommandPermissions::Promote, CommandPermissions::PromoteSame)
        tuple = {user.rank, services.access.ranks[user.rank]}
      elsif args.size == 2
        tuple = services.access.find_rank(args[1].downcase, args[1].to_i?)
      end

      unless tuple
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end
      unless promoted_user = services.database.get_user_by_arg(args[0])
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.no_user_found)
      end
      unless services.access.can_promote?(tuple[0], user.rank, promoted_user.rank, authority)
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      promoted_user.set_rank(tuple[0])
      services.database.update_user(promoted_user)

      services.relay.send_to_user(nil, promoted_user.id, Format.substitute_reply(services.replies.promoted, {
        "rank" => tuple[1].name,
      }))

      log = Format.substitute_message(services.logs.promoted, {
        "id"      => promoted_user.id.to_s,
        "name"    => promoted_user.get_formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.get_formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end
  end
end
