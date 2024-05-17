require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "promote", config: "enable_promote")]
  # A command used to promote a user to a given rank
  class PromoteCommand < CommandHandler
    # Promotes the user described in the *message* text or promotes the sender of the message it replies to, if *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

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
        promote_from_args(
          message.text,
          authority,
          user,
          message.message_id.to_i64,
          services
        )
      end
    end

    # Promotes a user who sent the *reply* message to the *user's* current rank if the rank has the `CommandPermissions::Promote` or `CommandPermissions::PromoteSame` permission
    # and no *arg* was given, or promotes to the given rank in *arg* if the *user's* rank has the `CommandPermissions::Promote` or `CommandPermissions::PromoteLower` permission
    # and one argument (name/value of rank) was given
    def promote_from_reply(arg : String?, authority : CommandPermissions, user : User, message : MessageID, reply : Tourmaline::Message, services : Services) : Nil
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

      return unless promoted_user = reply_user(user, reply, services)

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
        "name"    => promoted_user.formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end

    # Promotes a user given in the *text* to the *user's* current rank if the rank has the `CommandPermissions::Promote` or `CommandPermissions::PromoteSame` permission
    # and only one argument (the user's identifier) was given, or promotes to the given rank if the *user's* rank has the `CommandPermissions::Promote` or `CommandPermissions::PromoteLower` permission
    # and two arguments (the user's identifier and name/value of rank) was given
    def promote_from_args(text : String?, authority : CommandPermissions, user : User, message : MessageID, services : Services) : Nil
      unless (args = Format.get_args(text, count: 2)) && args.size > 0
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.missing_args)
      end

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
        "name"    => promoted_user.formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end
  end
end
