require "../../handlers.cr"
require "tourmaline"

module PrivateParlorXT
  @[RespondsTo(command: "start", config: "enable_start")]
  class StartCommand < CommandHandler
    @blacklist_contact : String?
    @registration_open : Bool?
    @pseudonymous : Bool?
    @default_rank : Int32

    def initialize(config : Config)
      @blacklist_contact = config.blacklist_contact
      @registration_open = config.registration_open
      @pseudonymous = config.pseudonymous
      @default_rank = config.default_rank
    end

    def do(ctx : Tourmaline::Context, relay : Relay, access : AuthorizedRanks, database : Database, history : History, locale : Locale)
      return unless (message = ctx.message) && (info = message.from)

      if user = database.get_user(info.id.to_i64)
        if user.blacklisted?
          response = Format.substitute_message(locale.replies.blacklisted, locale, {
            "contact" => Format.format_contact_reply(@blacklist_contact, locale),
            "reason"  => Format.format_reason_reply(user.blacklist_reason, locale),
          })

          relay.send_to_user(nil, user.id, response)
        elsif user.left?
          user.rejoin
          user.update_names(info.username, info.full_name)
          user.set_active
          database.update_user(user)

          relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.rejoined)

          log = Format.substitute_message(locale.logs.rejoined, locale, {"id" => user.id.to_s, "name" => user.get_formatted_name})

          relay.log_output(log)
        else
          user.update_names(info.username, info.full_name)
          user.set_active
          database.update_user(user)
          relay.send_to_user(message.message_id.to_i64, user.id, locale.replies.already_in_chat)
        end
      else
        unless @registration_open
          return relay.send_to_user(nil, info.id.to_i64, locale.replies.registration_closed)
        end

        if database.no_users?
          database.add_user(info.id.to_i64, info.username, info.full_name, access.max_rank)
        else
          database.add_user(info.id.to_i64, info.username, info.full_name, @default_rank)
        end

        if motd = database.get_motd
          relay.send_to_user(nil, info.id.to_i64, motd)
        end

        if @pseudonymous
          relay.send_to_user(message.message_id.to_i64, info.id.to_i64, locale.replies.joined_pseudonym)
        else
          relay.send_to_user(message.message_id.to_i64, info.id.to_i64, locale.replies.joined)
        end

        log = Format.substitute_message(locale.logs.joined, locale, {
          "id"   => info.id.to_s,
          "name" => info.username || info.full_name,
        })

        relay.log_output(log)
      end
    end
  end
end
