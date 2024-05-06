require "../../spec_helper.cr"

module PrivateParlorXT
  describe HearsHandler do
    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        services = create_services(relay: MockRelay.new("", MockClient.new))

        handler = HardCodedHearsHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: -10)

        handler.deny_user(user, services)

        messages = services.relay.as(MockRelay).empty_queue

        expected = Format.substitute_reply(services.replies.blacklisted, {
          "contact" => "",
          "reason"  => "",
        })

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end
  end
end