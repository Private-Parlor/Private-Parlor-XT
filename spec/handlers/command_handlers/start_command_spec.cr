require "../../spec_helper.cr"

module PrivateParlorXT\
  describe StartCommand do
    default_rank = 10

    client = MockClient.new
    config = HandlerConfig.new(
      MockConfig.new(
        default_rank: default_rank
      )
    )

    services = create_services(client: client, config: config)

    handler = StartCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client, config: config)

      test.run

      services.database.close
    end

    describe "#existing_user" do
      it "rejects blacklisted users" do
        generate_users(services.database)

        user = services.database.get_user(70000)

        unless user
          fail("User 70000 should exist in the database")
        end

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        blacklisted_user = services.database.get_user(70000)

        unless blacklisted_user
          fail("User 70000 should exist in the database")
        end

        blacklisted_user.username.should_not(eq("joined"))
        blacklisted_user.realname.should_not(eq("new user"))
      end

      it "rejoins users that have previously left" do
        generate_users(services.database)

        user = services.database.get_user(40000)

        unless user
          fail("User 40000 should exist in the database")
        end

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        rejoined_user = services.database.get_user(40000)

        unless rejoined_user
          fail("User 40000 should exist in the database")
        end

        rejoined_user.username.should_not(be_nil)
        rejoined_user.realname.should_not(eq("esimerkki"))
        rejoined_user.username.should(eq("joined"))
        rejoined_user.realname.should(eq("new user"))
        rejoined_user.left.should(be_nil)
      end

      it "updates activity for users that are already joined" do
        generate_users(services.database)

        user = services.database.get_user(60200)

        unless user
          fail("User 60200 should exist in the database")
        end

        previous_activity = user.last_active

        handler.existing_user(user, "joined", "new user", 1_i64, services)

        updated_user = services.database.get_user(60200)

        unless updated_user
          fail("User 60200 should exist in the database")
        end

        updated_user.username.should_not(eq("voorb"))
        updated_user.realname.should_not(eq("voorbeeld"))
        updated_user.username.should(eq("joined"))
        updated_user.realname.should(eq("new user"))
        updated_user.last_active.should(be > previous_activity)
      end
    end

    describe "#new_user" do
      it "rejects user if registration is closed" do
        closed_registration_handler = StartCommand.new(MockConfig.new(
          registration_open: false
          )
        )

        closed_registration_handler.new_user(9000, nil, "new user", 1_i64, services)

        services.database.get_user(9000).should(be_nil)
      end

      it "adds user to database with max rank" do
        handler.new_user(9000, nil, "new user", 1_i64, services)

        new_user = services.database.get_user(9000)

        unless new_user
          fail("User 9000 should have been added to the database")
        end

        new_user.rank.should(eq(services.access.max_rank))
      end

      it "adds user to database with default rank" do
        generate_users(services.database)

        handler.new_user(9000, nil, "new user", 1_i64, services)

        new_user = services.database.get_user(9000)

        unless new_user
          fail("User 9000 should have been added to the database")
        end

        new_user.rank.should(eq(default_rank))
      end
    end
  end
end