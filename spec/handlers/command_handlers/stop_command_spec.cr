require "../../spec_helper.cr"

module PrivateParlorXT
  describe StopCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = StopCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#do" do
      it "rejects users that have already left the chat" do
        generate_users(services.database)

        user = services.database.get_user(40000)

        unless user
          fail("User 40000 should exist in the database")
        end
        
        previous_left_time = user.left

        message = create_message(
          11,
          Tourmaline::User.new(40000, false, "esimerkki"),
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        left_user = services.database.get_user(40000)

        unless left_user
          fail("User 40000 should exist in the database")
        end

        left_user.left.should(eq(previous_left_time))
      end

      it "updates user as having left the chat" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "esimerkki"),
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        left_user = services.database.get_user(80300)

        unless left_user
          fail("User 80300 should exist in the database")
        end

        left_user.left.should_not(be_nil)
      end
    end
  end
end