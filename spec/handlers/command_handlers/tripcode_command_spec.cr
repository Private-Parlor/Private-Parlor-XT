require "../../spec_helper.cr"

module PrivateParlorXT
  describe TripcodeCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = TripcodeCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#do" do
      it "sets user tripcode" do
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(20000, false, "example"),
          text: "/tripcode name#password"
        )

        

        handler.do(message, services)

        updated_user = services.database.get_user(20000)

        unless updated_user
          fail("User 20000 should exist in the database")
        end

        updated_user.tripcode.should(eq("name#password"))
      end
    end

    describe "#valid_tripcode?" do
      it "returns false if arg does not contain a pound sign delimiter" do
        handler.valid_tripcode?("example").should(be_false)
      end

      it "returns false if arg ends with a pound sign delimiter" do
        handler.valid_tripcode?("example#").should(be_false)
      end

      it "returns false if arg contains a newline" do
        handler.valid_tripcode?("example\n#pass").should(be_false)
        handler.valid_tripcode?("example#pass\n").should(be_false)
      end

      it "returns false if length of arg is more than 30 characters" do
        handler.valid_tripcode?("example#AnExcessivelyLongTripcodePassword").should(be_false)
      end

      it "returns true if arg is formatted correctly" do
        handler.valid_tripcode?("example#1").should(be_true)
        handler.valid_tripcode?("example#password").should(be_true)
        handler.valid_tripcode?("example#verboselongpassword123").should(be_true)
      end
    end
  end
end
