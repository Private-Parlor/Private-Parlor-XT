require "../spec_helper.cr"

module PrivateParlorXT
  describe SpamHandler do
    describe "#expire" do
      it "removes decay amount from each user's spam score" do
        spam_handler = SpamHandler.new(
          spam_limit: 10000,
          decay_amount: 1000,
          score_animation: 3000,
          score_media_group: 5000,
          score_poll: 7000,
        )

        spam_handler.spammy_animation?(1500).should(be_false)
        spam_handler.spammy_album?(1700).should(be_false)
        spam_handler.spammy_poll?(1900).should(be_false)

        spam_handler.expire

        spam_handler.scores[1500].should(eq(2000))
        spam_handler.scores[1700].should(eq(4000))
        spam_handler.scores[1900].should(eq(6000))

        spam_handler.expire

        spam_handler.scores[1500].should(eq(1000))
        spam_handler.scores[1700].should(eq(3000))
        spam_handler.scores[1900].should(eq(5000))

        spam_handler.expire

        spam_handler.scores[1500]?.should(be_nil)
        spam_handler.scores[1700].should(eq(2000))
        spam_handler.scores[1900].should(eq(4000))
      end
    end
  end
end
