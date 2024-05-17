require "../../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "demote", config: "enable_demote")]
  # A command used to demote a user to the default rank or a given rank
  class DemoteCommand < CommandHandler
    # Demotes the user described in the *message* text or demotes the sender of the message it replies to, if *message* meets requirements
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      return unless authorized?(user, message, :Demote, services)

      if reply = message.reply_to_message
        arg = Format.get_arg(message.text)
        demote_from_reply(arg, user, message.message_id.to_i64, reply, services)
      else
        demote_from_args(message.text, user, message.message_id.to_i64, services)
      end
    end

    # Demotes a user who sent the *reply* message to the default rank if no *arg* was given,
    # or demotes to the given rank in *arg* if one argument (name/value of rank) was given
    def demote_from_reply(arg : String?, user : User, message : MessageID, reply : Tourmaline::Message, services : Services) : Nil
      if arg
        tuple = services.access.find_rank(arg.downcase, arg.to_i?)
      else
        tuple = {services.config.default_rank, services.access.ranks[services.config.default_rank]}
      end

      unless tuple
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      return unless demoted_user = reply_user(user, reply, services)

      unless services.access.can_demote?(tuple[0], user.rank, demoted_user.rank)
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      demoted_user.set_rank(tuple[0])
      services.database.update_user(demoted_user)

      log = Format.substitute_message(services.logs.demoted, {
        "id"      => demoted_user.id.to_s,
        "name"    => demoted_user.formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end

    # Demotes a user given in the *text* to the default rank if only one argument (the user's identifier) was given,
    # or demotes to the given rank if two arguments (the user's identifier and name/value of rank) was given
    def demote_from_args(text : String?, user : User, message : MessageID, services : Services) : Nil
      unless (args = Format.get_args(text, count: 2)) && args.size > 0
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.missing_args)
      end

      if args.size == 1
        tuple = {services.config.default_rank, services.access.ranks[services.config.default_rank]}
      elsif args.size == 2
        tuple = services.access.find_rank(args[1].downcase, args[1].to_i?)
      end

      unless tuple
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      unless demoted_user = services.database.get_user_by_arg(args[0])
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.no_user_found)
      end

      unless services.access.can_demote?(tuple[0], user.rank, demoted_user.rank)
        return services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      demoted_user.set_rank(tuple[0])
      services.database.update_user(demoted_user)

      log = Format.substitute_message(services.logs.demoted, {
        "id"      => demoted_user.id.to_s,
        "name"    => demoted_user.formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(ReplyParameters.new(message), user.id, services.replies.success)
    end
  end
end
