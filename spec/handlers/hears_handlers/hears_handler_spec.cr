require "../../spec_helper.cr"

module PrivateParlorXT
  describe HearsHandler do
    describe "#deny_user" do
      it "queues blacklisted response when user is blacklisted" do
        services = create_services()

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

    describe "#truncate_karma_reason" do
      it "returns first 500 characters of karma reason" do
        handler = HardCodedHearsHandler.new(MockConfig.new)

        reason = "lorem sed risus ultricies tristique nulla aliquet enim tortor at auctor
        urna nunc id cursus metus aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices
        sagittis orci a scelerisque purus semper eget duis at tellus at urna condimentum mattis pellentesque id nibh tortor
        id aliquet lectus proin nibh nisl condimentum id venenatis a condimentum vitae sapien pellentesque habitant morbi
        tristique senectus et netus et malesuada fames ac turpis egestas sed tempus urna et pharetra pharetra massa massa
        ultricies mi quis hendrerit dolor magna eget est lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque
        habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas integer eget aliquet nibh praesent
        tristique magna sit amet purus gravida quis blandit turpis cursus in hac habitasse platea dictumst quisque sagittis"

        expected = "lorem sed risus ultricies tristique nulla aliquet enim tortor at auctor
        urna nunc id cursus metus aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices
        sagittis orci a scelerisque purus semper eget duis at tellus at urna condimentum mattis pellentesque id nibh tortor
        id aliquet lectus proin nibh nisl condimentum id venenatis a condimentum vitae sapien pellentesque habitant morbi
        tristique senectus et netus et malesuada fames ac turpis egestas sed temp"

        unless result = handler.truncate_karma_reason(reason)
          fail("truncate_karma_reason should have returned a result")
        end

        result.should(eq(expected))
        result.size.should(eq(500))
      end

      it "returns nil if karma reason is nil" do
        handler = HardCodedHearsHandler.new(MockConfig.new)

        result = handler.truncate_karma_reason(nil)

        result.should(be_nil)
      end
    end

    describe "#karma_reason" do
      it "returns formatted karma reply with reason" do
        services = create_services

        handler = HardCodedHearsHandler.new(MockConfig.new)

        reply = "Karma vote with reason{karma_reason}"

        reason = "lorem sed risus\n" \
                 "ultricies tristique nulla\n" \
                 "aliquet enim tortor at auctor"

        expected = "Karma vote with reason\\ for:\n" \
                   ">lorem sed risus\n" \
                   ">ultricies tristique nulla\n" \
                   ">aliquet enim tortor at auctor"

        result = handler.karma_reason(reason, reply, services)

        result.should(eq(expected))
      end

      it "returns karma reply if reason is nil or empty" do
        services = create_services

        handler = HardCodedHearsHandler.new(MockConfig.new)

        expected = Format.substitute_reply(services.replies.gave_upvote, {} of String => String)

        result = handler.karma_reason(nil, services.replies.gave_upvote, services)
        result.should(eq(expected))

        result_two = handler.karma_reason("", services.replies.gave_upvote, services)
        result_two.should(eq(expected))

        result_three = handler.karma_reason("\\\\\\\\", services.replies.gave_upvote, services)
        result_three.should(eq(expected))
      end
    end
  end
end
