require "../../spec_helper.cr"

module PrivateParlorXT
  describe ToggleDebugCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = ToggleDebugCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#do" do
      it "toggles debug mode" do
        generate_users(services.database)

        user = services.database.get_user(20000)

        unless user
          fail("User 20000 should exist in the database")
        end
        
        previous_toggle = user.debug_enabled

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.debug_enabled.should_not(eq(previous_toggle))
      end
    end
  end
end