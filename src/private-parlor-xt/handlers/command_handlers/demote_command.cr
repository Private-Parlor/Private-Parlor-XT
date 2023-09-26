require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "demote", config: "enable_demote")]
  class DemoteCommand < CommandHandler
    def initialize(config : Config)
    end

    def do(context : Tourmaline::Context, services : Services) : Nil
      message, user = get_message_and_user(context, services)
      return unless message && user

      return unless authorized?(user, message, :Demote, services)

      if reply = message.reply_to_message
        arg = Format.get_arg(message.text)
        demote_from_reply(arg, user, message.message_id.to_i64, reply, services)
      else
        unless args = Format.get_args(message.text, count: 2)
          return services.relay.send_to_user(message.message_id.to_i64, user.id, services.replies.missing_args)
        end

        demote_from_args(args, user, message.message_id.to_i64, services)
      end
    end

    def demote_from_reply(arg : String?, user : User, message : MessageID, reply : Tourmaline::Message, services : Services)
      if arg
        tuple = services.access.find_rank(arg.downcase, arg.to_i?)
      else
        tuple = {services.config.default_rank, services.access.ranks[services.config.default_rank]}
      end

      unless tuple
        return services.relay.send_to_user(message, user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      return unless demoted_user = get_reply_user(user, reply, services)

      unless services.access.can_demote?(tuple[0], user.rank, demoted_user.rank)
        return services.relay.send_to_user(message, user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      demoted_user.set_rank(tuple[0])
      services.database.update_user(demoted_user)

      log = Format.substitute_message(services.logs.demoted, {
        "id"      => demoted_user.id.to_s,
        "name"    => demoted_user.get_formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.get_formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(message, user.id, services.replies.success)
    end

    def demote_from_args(args : Array(String), user : User, message : MessageID, services : Services)
      if args.size == 1
        tuple = {services.config.default_rank, services.access.ranks[services.config.default_rank]}
      elsif args.size == 2
        tuple = services.access.find_rank(args[1].downcase, args[1].to_i?)
      end

      unless tuple
        return services.relay.send_to_user(message, user.id, Format.substitute_reply(services.replies.no_rank_found, {
          "ranks" => services.access.rank_names(limit: user.rank).to_s,
        }))
      end

      unless demoted_user = services.database.get_user_by_arg(args[0])
        return services.relay.send_to_user(message, user.id, services.replies.no_user_found)
      end

      unless services.access.can_demote?(tuple[0], user.rank, demoted_user.rank)
        return services.relay.send_to_user(message, user.id, services.replies.fail)
      end

      update_user_activity(user, services)

      demoted_user.set_rank(tuple[0])
      services.database.update_user(demoted_user)

      log = Format.substitute_message(services.logs.demoted, {
        "id"      => demoted_user.id.to_s,
        "name"    => demoted_user.get_formatted_name,
        "rank"    => tuple[1].name,
        "invoker" => user.get_formatted_name,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(message, user.id, services.replies.success)
    end
  end
end
