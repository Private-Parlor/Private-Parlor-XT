require "../../spec_helper.cr"

module PrivateParlorXT
  describe PurgeCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = PurgeCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#do" do
      it "deletes all message groups sent by the blacklisted user" do
        generate_users(services.database)
        generate_history(services.history)

        # Update blacklisted user
        unless user = services.database.get_user(70000)
          fail("User 70000 should exist in the database")
        end

        user.set_left
        services.database.update_user(user)

        services.history.new_message(70000, 11)
        services.history.new_message(70000, 15)

        services.history.add_to_history(11, 12, 20000)
        services.history.add_to_history(11, 13, 80300)
        services.history.add_to_history(11, 14, 60200)

        services.history.add_to_history(15, 16, 20000)
        services.history.add_to_history(15, 17, 80300)
        services.history.add_to_history(15, 18, 60200)

        message = create_message(
          50,
          Tourmaline::User.new(20000, false, "example"),
        )

        handler.do(message, services)

        services.history.get_origin_message(12).should(be_nil)
        services.history.get_origin_message(13).should(be_nil)
        services.history.get_origin_message(14).should(be_nil)
        services.history.get_origin_message(15).should(be_nil)
        services.history.get_origin_message(16).should(be_nil)
        services.history.get_origin_message(17).should(be_nil)
        services.history.get_origin_message(18).should(be_nil)
      end
    end
  end
end
