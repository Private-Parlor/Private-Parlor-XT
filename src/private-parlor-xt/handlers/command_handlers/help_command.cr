require "../command_handler.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "help", config: "enable_help")]
  # A command used to view the commands that one can use
  class HelpCommand < CommandHandler
    # Returns a message containing commands that the sender of the *message* can use
    def do(message : Tourmaline::Message, services : Services) : Nil
      return unless user = user_from_message(message, services)

      update_user_activity(user, services)

      services.relay.send_to_user(
        ReplyParameters.new(message.message_id),
        user.id,
        help(user, services.access.ranks, services)
      )
    end

    # Returns a generated message containing the commands the user can use based on his rank.
    def help(user : User, ranks : Hash(Int32, Rank), services : Services) : String
      ranked = {
        CommandPermissions::Promote      => "/promote [name/OID/ID] [rank] - #{services.descriptions.promote}",
        CommandPermissions::PromoteSame  => "/promote [name/OID/ID] [rank] - #{services.descriptions.promote}",
        CommandPermissions::PromoteLower => "/promote [name/OID/ID] [rank] - #{services.descriptions.promote}",
        CommandPermissions::Demote       => "/demote [name/OID/ID] [rank] - #{services.descriptions.demote}",
        CommandPermissions::Ranksay      => "/#{ranks[user.rank].name.downcase}say [text] - #{services.descriptions.ranksay}",
        CommandPermissions::Sign         => "/sign [text] - #{services.descriptions.sign}",
        CommandPermissions::TSign        => "/tsign [text] - #{services.descriptions.tsign}",
        CommandPermissions::Uncooldown   => "/uncooldown [name/OID] - #{services.descriptions.uncooldown}",
        CommandPermissions::Whitelist    => "/whitelist [ID] - #{services.descriptions.whitelist}",
        CommandPermissions::Purge        => "/purge - #{services.descriptions.purge}",
        CommandPermissions::MotdSet      => "/motd - #{services.descriptions.motd_set}",
        CommandPermissions::Unblacklist  => "/unblacklist [name/ID]  - #{services.descriptions.unblacklist}",
      }

      reply_required = {
        CommandPermissions::Upvote     => "+1 - #{services.descriptions.upvote}",
        CommandPermissions::Downvote   => "-1 - #{services.descriptions.downvote}",
        CommandPermissions::Warn       => "/warn [reason] - #{services.descriptions.warn}",
        CommandPermissions::Delete     => "/delete [reason] - #{services.descriptions.delete}",
        CommandPermissions::Spoiler    => "/spoiler - #{services.descriptions.spoiler}",
        CommandPermissions::Remove     => "/remove [reason] - #{services.descriptions.remove}",
        CommandPermissions::Blacklist  => "/blacklist [reason] - #{services.descriptions.blacklist}",
        CommandPermissions::RankedInfo => "/info - #{services.descriptions.ranked_info}",
        CommandPermissions::Reveal     => "/reveal - #{services.descriptions.reveal}",
        CommandPermissions::Pin        => "/pin - #{services.descriptions.pin}",
        CommandPermissions::Unpin      => "/unpin - #{services.descriptions.unpin}",
      }

      String.build do |str|
        str << services.replies.help_header
        str << "\n"
        str << Format.escape_mdv2("/start - #{services.descriptions.start}\n")
        str << Format.escape_mdv2("/stop - #{services.descriptions.stop}\n")
        str << Format.escape_mdv2("/info - #{services.descriptions.info}\n")
        str << Format.escape_mdv2("/users - #{services.descriptions.users}\n")
        str << Format.escape_mdv2("/version - #{services.descriptions.version}\n")
        str << Format.escape_mdv2("/toggle_karma - #{services.descriptions.toggle_karma}\n")
        str << Format.escape_mdv2("/toggle_debug - #{services.descriptions.toggle_debug}\n")
        str << Format.escape_mdv2("/tripcode - #{services.descriptions.tripcode}\n")
        str << Format.escape_mdv2("/motd - #{services.descriptions.motd}\n")
        str << Format.escape_mdv2("/help - #{services.descriptions.help}\n")
        str << Format.escape_mdv2("/stats - #{services.descriptions.stats}\n")

        next unless rank = ranks[user.rank]?

        rank_commands = [] of String
        reply_commands = [] of String

        if rank.command_permissions.includes?(CommandPermissions::RanksayLower)
          lower_ranks = ranks.select { |k, _| k <= user.rank && k != -10 }

          lower_ranks.each do |_, v|
            ranksay_permissions = Set{CommandPermissions::Ranksay, CommandPermissions::RanksayLower}

            unless (v.command_permissions & ranksay_permissions).empty?
              rank_commands << Format.escape_mdv2("/#{services.access.ranksay(v.name)}say [text] - #{services.descriptions.ranksay}")
            end
          end
        end

        rank.command_permissions.each do |permission|
          if ranked.keys.includes?(permission)
            rank_commands << Format.escape_mdv2(ranked[permission])
          elsif reply_required.keys.includes?(permission)
            reply_commands << Format.escape_mdv2(reply_required[permission])
          end
        end

        unless rank_commands.empty?
          str << "\n"
          str << Format.substitute_reply(services.replies.help_rank_commands, {"rank" => rank.name})
          str << "\n"
          rank_commands.each { |line| str << "#{line}\n" }
        end
        unless reply_commands.empty?
          str << "\n"
          str << services.replies.help_reply_commands
          str << "\n"
          reply_commands.each { |line| str << "#{line}\n" }
        end
      end
    end
  end
end
