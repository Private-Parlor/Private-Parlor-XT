require "../spec_helper.cr"

module PrivateParlorXT
  describe SpamHandler do
    describe "#spammy_sign?" do
      it "returns true if user is spamming message signs" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_sign?(9000, 600).should(be_false)
      end

      it "returns false if user is not spamming message signs" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_sign?(9000, 600)
        spam_handler.spammy_sign?(9000, 600).should(be_true)
      end
    end

    describe "#spammy_upvote?" do
      it "returns true if user is spamming upvotes" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_upvote?(9000, 600).should(be_false)
      end

      it "returns false if user is not spamming upvotes" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_upvote?(9000, 600)
        spam_handler.spammy_upvote?(9000, 600).should(be_true)
      end
    end

    describe "#spammy_downvote?" do
      it "returns true if user is spamming downvotes" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_downvote?(9000, 600).should(be_false)
      end

      it "returns false if user is not spamming downvotes" do
        spam_handler = SpamHandler.new()
        
        spam_handler.spammy_downvote?(9000, 600)
        spam_handler.spammy_downvote?(9000, 600).should(be_true)
      end
    end

    describe "#spammy_text?" do
      it "returns true if user is spamming text messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_text: 1000,
          score_character: 2,
          score_line: 100,
        )

        spam_handler.spammy_text?(9000, "Example line of text").should(be_false)
      end

      it "returns false if user is not spamming text messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_text: 1000,
          score_character: 2,
          score_line: 100,
        )

        spam_handler.spammy_text?(9000, "Example line of text")
        spam_handler.spammy_text?(9000, "Example line of text").should(be_true)
      end
    end

    describe "#spammy_photo?" do
      it "returns true if user is spamming photos" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_photo: 1500,
        )

        spam_handler.spammy_photo?(9000).should(be_false)
      end

      it "returns false if user is not spamming photos" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_photo: 1500,
        )

        spam_handler.spammy_photo?(9000)
        spam_handler.spammy_photo?(9000).should(be_true)
      end
    end

    describe "#spammy_animation?" do
      it "returns true if user is spamming GIFs" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_animation: 1500,
        )

        spam_handler.spammy_animation?(9000).should(be_false)
      end

      it "returns false if user is not spamming GIFs" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_animation: 1500,
        )

        spam_handler.spammy_animation?(9000)
        spam_handler.spammy_animation?(9000).should(be_true)
      end
    end

    describe "#spammy_video?" do
      it "returns true if user is spamming videos" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_video: 1500,
        )

        spam_handler.spammy_video?(9000).should(be_false)
      end

      it "returns false if user is not spamming videos" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_video: 1500,
        )

        spam_handler.spammy_video?(9000)
        spam_handler.spammy_video?(9000).should(be_true)
      end
    end

    describe "#spammy_audio?" do
      it "returns true if user is spamming audio messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_audio: 1500,
        )

        spam_handler.spammy_audio?(9000).should(be_false)
      end

      it "returns false if user is not spamming audio messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_audio: 1500,
        )

        spam_handler.spammy_audio?(9000)
        spam_handler.spammy_audio?(9000).should(be_true)
      end
    end

    describe "#spammy_voice?" do
      it "returns true if user is spamming voice messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_voice: 1500,
        )

        spam_handler.spammy_voice?(9000).should(be_false)
      end

      it "returns false if user is not spamming voice messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_voice: 1500,
        )

        spam_handler.spammy_voice?(9000)
        spam_handler.spammy_voice?(9000).should(be_true)
      end
    end

    describe "#spammy_document?" do
      it "returns true if user is spamming files" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_document: 1500,
        )

        spam_handler.spammy_document?(9000).should(be_false)
      end

      it "returns false if user is not spamming files" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_document: 1500,
        )

        spam_handler.spammy_document?(9000)
        spam_handler.spammy_document?(9000).should(be_true)
      end
    end

    describe "#spammy_poll?" do
      it "returns true if user is spamming polls" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_poll: 1500,
        )

        spam_handler.spammy_poll?(9000).should(be_false)
      end

      it "returns false if user is not spamming polls" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_poll: 1500,
        )

        spam_handler.spammy_poll?(9000)
        spam_handler.spammy_poll?(9000).should(be_true)
      end
    end

    describe "#spammy_forward?" do
      it "returns true if user is spamming forwarded messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_forwarded_message: 1500,
        )

        spam_handler.spammy_forward?(9000).should(be_false)
      end

      it "returns false if user is not spamming forwarded messages" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_forwarded_message: 1500,
        )

        spam_handler.spammy_forward?(9000)
        spam_handler.spammy_forward?(9000).should(be_true)
      end
    end

    describe "#spammy_video_note?" do
      it "returns true if user is spamming video notes" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_video_note: 1500,
        )

        spam_handler.spammy_video_note?(9000).should(be_false)
      end

      it "returns false if user is not spamming video notes" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_video_note: 1500,
        )

        spam_handler.spammy_video_note?(9000)
        spam_handler.spammy_video_note?(9000).should(be_true)
      end
    end

    describe "#spammy_sticker?" do
      it "returns true if user is spamming stickers" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_sticker: 1500,
        )

        spam_handler.spammy_sticker?(9000).should(be_false)
      end

      it "returns false if user is not spamming stickers" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_sticker: 1500,
        )

        spam_handler.spammy_sticker?(9000)
        spam_handler.spammy_sticker?(9000).should(be_true)
      end
    end

    describe "#spammy_album?" do
      it "returns true if user is spamming albums" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_media_group: 1500,
        )

        spam_handler.spammy_album?(9000).should(be_false)
      end

      it "returns false if user is not spamming albums" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_media_group: 1500,
        )

        spam_handler.spammy_album?(9000)
        spam_handler.spammy_album?(9000).should(be_true)
      end
    end

    describe "#spammy_venue?" do
      it "returns true if user is spamming venues" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_venue: 1500,
        )

        spam_handler.spammy_venue?(9000).should(be_false)
      end

      it "returns false if user is not spamming venues" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_venue: 1500,
        )

        spam_handler.spammy_venue?(9000)
        spam_handler.spammy_venue?(9000).should(be_true)
      end
    end

    describe "#spammy_location?" do
      it "returns true if user is spamming locations" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_location: 1500,
        )

        spam_handler.spammy_location?(9000).should(be_false)
      end

      it "returns false if user is not spamming locations" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_location: 1500,
        )

        spam_handler.spammy_location?(9000)
        spam_handler.spammy_location?(9000).should(be_true)
      end
    end

    describe "#spammy_contact?" do
      it "returns true if user is spamming contacts" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_contact: 1500,
        )

        spam_handler.spammy_contact?(9000).should(be_false)
      end

      it "returns false if user is not spamming contacts" do
        spam_handler = SpamHandler.new(
          spam_limit: 2000,
          score_contact: 1500,
        )

        spam_handler.spammy_contact?(9000)
        spam_handler.spammy_contact?(9000).should(be_true)
      end
    end

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
