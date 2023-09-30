require "../spec_helper.cr"

module PrivateParlorXT
  describe MockUser do
    describe "#to_array" do
    end

    describe "#get_formatted_name" do
      it "returns username if user has a username" do
        user = MockUser.new(9000, "new_user")

        user.get_formatted_name.should(eq("@new_user"))
      end

      it "returns real name if user does not have a username" do
        user = MockUser.new(9000, nil, "New User")

        user.get_formatted_name.should(eq("New User"))
      end
    end

    describe "#get_obfuscated_id" do
      it "generates obfuscated id" do
        expected = Random.new(9000 + Time.utc.at_beginning_of_day.to_unix).base64(3)

        user = MockUser.new(9000)

        user.get_obfuscated_id.should(eq(expected))
      end
    end

    describe "#get_obfuscated_karma" do
      it "generates obfuscated karma" do
        user_one = MockUser.new(5000, karma: 25)

        user_two = MockUser.new(7000, karma: 0)

        user_three = MockUser.new(9000, karma: -25)

        user_one.get_obfuscated_karma.should(be_close(25, 7))

        user_two.get_obfuscated_karma.should(be_close(0, 2))

        user_three.get_obfuscated_karma.should(be_close(-25, 7))
      end
    end

    describe "#rejoin" do
      it "removes user's left time" do
        left_time = Time.utc

        user = MockUser.new(9000, left: left_time)

        user.rejoin

        user.left.should_not(eq(left_time))
        user.left.should(be_nil)
      end
    end

    describe "#update_names" do
      it "updates username and real name" do
        user = MockUser.new(9000, username: "new_user", realname: "New User")

        user.update_names("updated_user", "Updated User")

        user.username.should(eq("updated_user"))
        user.realname.should(eq("Updated User"))
      end
    end

    describe "#set_active" do
      it "updates user activity" do
        previous_activity_time = Time.utc(2023, 1, 1)

        user = MockUser.new(9000)

        user.set_active

        user.last_active.should(be > previous_activity_time)
      end
    end

    describe "#set_left" do
      it "sets user's left time" do
        user = MockUser.new(9000, left: nil)

        user.set_left

        user.left.should_not(be_nil)
      end
    end

    describe "#set_rank" do
      it "updates user's rank" do
        user = MockUser.new(9000, rank: 0)

        user.set_rank(-10)

        user.rank.should(eq(-10))
      end
    end

    describe "#set_tripcode" do
      it "sets user's tripcode" do
        user = MockUser.new(9000, tripcode: nil)

        user.set_tripcode("User#SecurePassword")

        user.tripcode.should(eq("User#SecurePassword"))
      end
    end

    describe "#toggle_karma" do
      it "negates user's karma notification toggle" do
        user = MockUser.new(9000, hide_karma: false)

        user.toggle_karma

        user.hide_karma.should(be_true)
      end
    end

    describe "#toggle_debug" do
      it "negates user's debug mode toggle" do
        user = MockUser.new(9000, debug_enabled: false)

        user.toggle_debug

        user.debug_enabled.should(be_true)
      end
    end

    describe "#increment_karma" do
      it "increases user's karma by the given amount" do
        user = MockUser.new(9000, karma: 25)

        user.increment_karma(25)

        user.karma.should(eq(50))
      end
    end

    describe "#decrement_karma" do
      it "decreases user's karma by the given amount" do
        user = MockUser.new(9000, karma: 25)

        user.decrement_karma(25)

        user.karma.should(eq(0))
      end
    end

    describe "#cooldown" do
      it "sets user cooldown based on number of warnings" do
        user = MockUser.new(9000, warnings: 2, cooldown_until: nil)

        user.cooldown(5)

        unless cooldown = user.cooldown_until
          fail("Cooldown should not be nil")
        end

        (cooldown - Time.utc).should(be < 25.minutes)
      end

      it "sets user cooldown to 1 year at most" do
        user = MockUser.new(9000, warnings: 9, cooldown_until: nil)

        user.cooldown(5)

        unless cooldown = user.cooldown_until
          fail("Cooldown should not be nil")
        end

        (cooldown - Time.utc).should(be < 52.weeks)
      end

      it "sets user cooldown to given time span" do
        user = MockUser.new(9000, cooldown_until: nil)

        user.cooldown(120.seconds)

        unless cooldown = user.cooldown_until
          fail("Cooldown should not be nil")
        end

        (cooldown - Time.utc).should(be < 2.minutes)
      end
    end

    describe "#warn" do
      it "adds a warning and updates user warn expiry" do
        user = MockUser.new(9000, warn_expiry: nil)

        user.warn(24)

        user.warnings.should(eq(1))
        user.warn_expiry.should_not(be_nil)
      end
    end

    describe "#blacklist" do
      it "sets user as left, blacklisted, and updates reason" do
        user = MockUser.new(9000, left: nil)

        user.blacklist("Reason for Blacklist")

        user.rank.should(eq(-10))
        user.left.should_not(be_nil)
        user.blacklist_reason.should(eq("Reason for Blacklist"))
      end
    end

    describe "#remove_cooldown" do
      it "removes cooldown if cooldown has expired" do
        user = MockUser.new(9000, cooldown_until: Time.utc(2023, 1, 1))

        user.remove_cooldown

        user.cooldown_until.should(be_nil)
      end

      it "removes cooldown if given a true value" do
        cooldown_year = Time.utc.year + 1
        user = MockUser.new(9000, cooldown_until: Time.utc(cooldown_year, 1, 1))

        user.remove_cooldown

        user.cooldown_until.should_not(be_nil)

        user.remove_cooldown(true)

        user.cooldown_until.should(be_nil)
      end
    end

    describe "#remove_warning" do
      it "removes warning and resets warning expiration" do
        previous_warn_expiration = Time.utc
        user = MockUser.new(9000, warnings: 3, warn_expiry: previous_warn_expiration)

        user.remove_warning(1, 24.hours)

        unless current_warn_expiration = user.warn_expiry
          fail("User warn expiry should not be nil")
        end

        user.warnings.should(eq(2))
        current_warn_expiration.should(be > previous_warn_expiration)
      end

      it "removes warning and sets warning expiration to nil if no warnings left" do
        user = MockUser.new(9000, warnings: 1, warn_expiry: Time.utc)

        user.remove_warning(1, 24.hours)

        user.warnings.should(eq(0))
        user.warn_expiry.should(be_nil)
      end
    end

    describe "#blacklisted?" do
      it "returns true if user is blacklsited" do
        user = MockUser.new(9000, rank: -10)

        user.blacklisted?.should(be_true)
      end

      it "returns false if user is not blacklsited" do
        user = MockUser.new(9000, rank: 0)

        user.blacklisted?.should(be_false)
      end
    end

    describe "#left?" do
      it "returns true if user has left the chat" do
        user = MockUser.new(9000, left: Time.utc)

        user.left?.should(be_true)
      end

      it "returns false if user has not left the chat" do
        user = MockUser.new(9000, left: nil)

        user.left?.should(be_false)
      end
    end

    describe "#can_chat?" do
      it "returns true if user is not on cooldown, left, blacklisted, or media limited" do
        user = MockUser.new(9000, joined: Time.utc(2023, 1, 1))

        user.can_chat?(24.hours).should(be_true)
      end

      it "returns true if user is not on cooldown, left, blacklisted, or media limited; user has a rank" do
        user = MockUser.new(9000, rank: 10)

        user.can_chat?(24.hours).should(be_true)
      end

      it "returns true if user is not on cooldown, left, or blacklisted; media limit is 0" do
        user = MockUser.new(9000)

        user.can_chat?(0.hours).should(be_true)
      end

      it "returns false if user is on cooldown" do
        cooldown_year = Time.utc.year + 1
        user = MockUser.new(9000, cooldown_until: Time.utc(cooldown_year, 1, 1))

        user.can_chat?(0.hours).should(be_false)
      end

      it "returns false if user is blacklisted" do
        user = MockUser.new(9000, rank: -10)

        user.can_chat?(0.hours).should(be_false)
      end

      it "returns false if user has left the chat" do
        user = MockUser.new(9000, left: Time.utc)

        user.can_chat?(0.hours).should(be_false)
      end

      it "returns false if user is media limited" do
        user = MockUser.new(9000)

        user.can_chat?(24.hours).should(be_false)
      end
    end

    describe "#can_use_command?" do
      it "returns true if user is not blacklisted and has not left the chat" do
        user = MockUser.new(9000)

        user.can_use_command?.should(be_true)
      end

      it "returns false if user is blacklsited" do
        user = MockUser.new(9000, rank: -10)

        user.can_use_command?.should(be_false)
      end

      it "returns false if user has left the chat" do
        user = MockUser.new(9000, left: Time.utc)

        user.can_use_command?.should(be_false)
      end
    end
  end
end
