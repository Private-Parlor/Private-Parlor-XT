require "../../spec_helper.cr"

module PrivateParlorXT
  describe ToggleKarmaCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = ToggleKarmaCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#do" do
      it "toggles karma notifications" do
        generate_users(services.database)

        user = services.database.get_user(20000)

        unless user
          fail("User 20000 should exist in the database")
        end

        previous_toggle = user.hide_karma

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
        )

        

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.hide_karma.should_not(eq(previous_toggle))
      end
    end
  end
end
