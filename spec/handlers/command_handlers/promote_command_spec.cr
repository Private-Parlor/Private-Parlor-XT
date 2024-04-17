require "../../spec_helper.cr"

module PrivateParlorXT
  describe PromoteCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = PromoteCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#promote_from_reply" do
      it "promotes reply user to invoker's current rank" do
        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_reply(nil, :PromoteSame, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(1000))
      end

      it "promotes reply user to given rank" do
        reply_to = create_message(
          9,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        )

        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_reply("mod", :Promote, user, 11, reply_to, services)

        unless reply_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        reply_user.rank.should(eq(10))
      end
    end

    describe "#promote_from_args" do
      it "promotes given user to invoker's current rank" do
        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          ["voorb"],
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(1000))
      end

      it "promotes given user to given rank" do
        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          ["voorb", "mod"],
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(60200)
          fail("User 60200 should exist in the database")
        end

        promoted_user.rank.should(eq(10))
      end

      it "does not promote banned users (unbans)" do
        unless user = services.database.get_user(20000)
          fail("User 20000 should exist in the database")
        end

        handler.promote_from_args(
          ["70000", "user"],
          :Promote,
          user,
          11,
          services
        )

        unless promoted_user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        promoted_user.rank.should(eq(-10))
      end
    end
  end
end
