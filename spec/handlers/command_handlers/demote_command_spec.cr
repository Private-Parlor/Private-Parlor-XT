require "../../spec_helper.cr"

module PrivateParlorXT
  describe DemoteCommand do
    default_rank = 0

    client = MockClient.new
    config = HandlerConfig.new(
      MockConfig.new(
        default_rank: default_rank
      )
    )

    services = create_services(client: client, config: config)

    handler = DemoteCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client, config: config)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#demote_from_reply" do
      it "demotes reply user to default rank" do
        reply_to = create_message(
          3,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_reply(nil, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user.rank.should(eq(default_rank))
      end

      it "demotes reply user to the given rank" do
        # Set user rank to admin for this test
        unless promoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        promoted_user.set_rank(100)

        services.database.update_user(promoted_user)

        reply_to = create_message(
          3,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_reply("mod", user, 11, reply_to, services)

        unless reply_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        reply_user.rank.should(eq(10))
      end
    end

    describe "#demote_from_args" do
      it "demotes given user to default rank" do
        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_args(
          ["80300"],
          user,
          11,
          services
        )

        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        demoted_user.rank.should(eq(default_rank))
      end

      it "demotes given user to the given rank" do
        # Set user rank to admin for this test
        unless promoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        promoted_user.set_rank(100)

        services.database.update_user(promoted_user)

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.demote_from_args(
          ["80300", "mod"],
          user,
          11,
          services
        )

        unless demoted_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        demoted_user.rank.should(eq(10))
      end
    end
  end
end
