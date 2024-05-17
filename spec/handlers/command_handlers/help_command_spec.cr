require "../../spec_helper.cr"

module PrivateParlorXT
  describe HelpCommand do
    describe "#do" do
      it "updates user activity" do
        services = create_services()

        handler = HelpCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/help",
          from: tourmaline_user,
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "returns message containing information about commands avaiable to the user" do
        services = create_services()

        handler = HelpCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/help",
          from: tourmaline_user,
        )

        handler.do(message, services)

        expected = handler.help(user, services.access.ranks, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(1))

        messages[0].data.should(eq(expected))
      end
    end

    describe "#help" do
      it "returns dynamically generated help message according to user's rank" do
        services = create_services

        handler = HelpCommand.new(MockConfig.new)

        user = MockUser.new(9000, rank: 1000)

        expected = "#{services.replies.help_header}\n" \
                   "#{Format.escape_mdv2("/start - #{services.descriptions.start}\n")}" \
                   "#{Format.escape_mdv2("/stop - #{services.descriptions.stop}\n")}" \
                   "#{Format.escape_mdv2("/info - #{services.descriptions.info}\n")}" \
                   "#{Format.escape_mdv2("/users - #{services.descriptions.users}\n")}" \
                   "#{Format.escape_mdv2("/version - #{services.descriptions.version}\n")}" \
                   "#{Format.escape_mdv2("/toggle_karma - #{services.descriptions.toggle_karma}\n")}" \
                   "#{Format.escape_mdv2("/toggle_debug - #{services.descriptions.toggle_debug}\n")}" \
                   "#{Format.escape_mdv2("/tripcode - #{services.descriptions.tripcode}\n")}" \
                   "#{Format.escape_mdv2("/motd - #{services.descriptions.motd}\n")}" \
                   "#{Format.escape_mdv2("/help - #{services.descriptions.help}\n")}" \
                   "#{Format.escape_mdv2("/stats - #{services.descriptions.stats}\n")}" \
                   "\n#{Format.substitute_reply(services.replies.help_rank_commands, {"rank" => "Host"})}\n" \
                   "#{Format.escape_mdv2("/hostsay [text] - #{services.descriptions.ranksay}\n")}" \
                   "#{Format.escape_mdv2("/adminsay [text] - #{services.descriptions.ranksay}\n")}" \
                   "#{Format.escape_mdv2("/modsay [text] - #{services.descriptions.ranksay}\n")}" \
                   "#{Format.escape_mdv2("/purge - #{services.descriptions.purge}\n")}" \
                   "#{Format.escape_mdv2("/promote [name/OID/ID] [rank] - #{services.descriptions.promote}\n")}" \
                   "#{Format.escape_mdv2("/demote [name/OID/ID] [rank] - #{services.descriptions.demote}\n")}" \
                   "\n#{services.replies.help_reply_commands}\n" \
                   "#{Format.escape_mdv2("+1 - #{services.descriptions.upvote}\n")}" \
                   "#{Format.escape_mdv2("-1 - #{services.descriptions.downvote}\n")}"

        result = handler.help(user, services.access.ranks, services)

        result.should(eq(expected))
      end
    end
  end
end
