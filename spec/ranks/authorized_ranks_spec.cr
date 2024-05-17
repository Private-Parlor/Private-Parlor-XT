require "../spec_helper.cr"

module PrivateParlorXT
  describe AuthorizedRanks do
    # Create ranks with a limited set of permissions
    ranks = {
      1000 => Rank.new(
        "Host",
        Set{
          CommandPermissions::Promote,
          CommandPermissions::Demote,
          CommandPermissions::RanksayLower,
        },
        Set{
          MessagePermissions::Text,
          MessagePermissions::Photo,
        },
      ),
      100 => Rank.new(
        "Admin",
        Set{
          CommandPermissions::PromoteLower,
          CommandPermissions::Demote,
          CommandPermissions::RanksayLower,
        },
        Set{
          MessagePermissions::Text,
          MessagePermissions::Photo,
        },
      ),
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::PromoteSame,
          CommandPermissions::Ranksay,
        },
        Set{
          MessagePermissions::Text,
          MessagePermissions::Photo,
        },
      ),
      0 => Rank.new(
        "User",
        Set{
          CommandPermissions::Upvote,
        },
        Set{
          MessagePermissions::Text,
        },
      ),
      -10 => Rank.new(
        "Blacklisted",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    authorized_ranks = AuthorizedRanks.new(ranks)

    describe "#authorized?" do
      it "returns true if user is authorized to use command" do
        authorized_ranks.authorized?(0, :Upvote).should(be_true)
      end

      it "returns the permission if user is authorized to use one of the given commands" do
        permission = authorized_ranks.authorized?(100, :Ranksay, :RanksayLower)

        permission.should(eq(CommandPermissions::RanksayLower))
      end

      it "returns true if user is authorized to use a message type" do
        authorized_ranks.authorized?(10, :Photo).should(be_true)
      end

      it "returns false or nil if use is not authorized to use command" do
        authorized_ranks.authorized?(0, :Pin).should(be_falsey)
      end

      it "returns false or nil if user can not use any of the given commands" do
        permission = authorized_ranks.authorized?(0, :Ranksay, :RanksayLower)

        permission.should(be_falsey)
      end

      it "returns false or nil if user cannot use a message type" do
        authorized_ranks.authorized?(0, :Photo).should(be_falsey)
      end
    end

    describe "#max_rank" do
      it "returns the value of the max rank" do
        authorized_ranks.max_rank.should(eq(1000))
      end
    end

    describe "#rank_name" do
      it "returns the name of the rank with the given value if it exists" do
        name = authorized_ranks.rank_name(1000)

        unless name
          fail("There should be a 'Host' rank")
        end

        name.should(eq("Host"))
      end

      it "returns nil if a rank with that name does not exist" do
        name = authorized_ranks.rank_name(12345)

        name.should(be_nil)
      end
    end

    describe "#ranksay_ranks" do
      it "returns an array of strings that can use the ranksay command" do
        expected = ["Mod", "Admin", "Host"].sort

        authorized_ranks.ranksay_ranks.sort.should(eq(expected))
      end
    end

    describe "#find_rank" do
      it "finds rank from a given name" do
        tuple = authorized_ranks.find_rank("admin")

        unless tuple
          fail("There should be an 'Admin' rank")
        end

        tuple[0].should(eq(100))
        tuple[1].name.should(eq("Admin"))
      end

      it "finds rank from a given value" do
        tuple = authorized_ranks.find_rank("administrator", 100)

        unless tuple
          fail("There should be an 'Admin' rank")
        end

        tuple[0].should(eq(100))
        tuple[1].name.should(eq("Admin"))
      end

      it "returns nil if no rank with the given name or value exists" do
        tuple = authorized_ranks.find_rank("Superuser", 12345)

        tuple.should(be_nil)
      end
    end

    describe "#can_promote?" do
      it "can't promote user to a lower rank" do
        authorized_ranks.can_promote?(0, 100, 10, CommandPermissions::Promote).should(be_false)
      end

      it "can't promote a user to a rank higher than invoker rank" do
        authorized_ranks.can_promote?(1000, 100, 10, CommandPermissions::Promote).should(be_false)
      end

      it "can't promote a user to blacklisted rank" do
        authorized_ranks.can_promote?(-10, 100, 10, CommandPermissions::Promote).should(be_false)
      end

      it "can promote user to same or lower rank with Promote permission" do
        authorized_ranks.can_promote?(100, 100, 0, CommandPermissions::Promote).should(be_true)

        authorized_ranks.can_promote?(10, 100, 0, CommandPermissions::Promote).should(be_true)
      end

      it "can promote user to lower rank, but not same rank, with PromoteLower permission" do
        authorized_ranks.can_promote?(10, 100, 0, CommandPermissions::PromoteLower).should(be_true)

        authorized_ranks.can_promote?(100, 100, 0, CommandPermissions::PromoteLower).should(be_false)
      end

      it "can promote user to same rank, but not lower rank, with PromoteSame permission" do
        authorized_ranks.can_promote?(100, 100, 0, CommandPermissions::PromoteSame).should(be_true)

        authorized_ranks.can_promote?(10, 100, 0, CommandPermissions::PromoteSame).should(be_false)
      end
    end

    describe "#can_demote?" do
      it "returns true if user can be demoted to the given rank" do
        authorized_ranks.can_demote?(0, 100, 10).should(be_true)
      end

      it "can't demote users with higher ranks" do
        authorized_ranks.can_demote?(0, 10, 100).should(be_false)
      end

      it "can't demote users with the same rank" do
        authorized_ranks.can_demote?(0, 10, 10).should(be_false)
      end

      it "can't demote user to blacklisted rank" do
        authorized_ranks.can_demote?(-10, 100, 10).should(be_false)
      end

      it "can't demote user to a higher rank" do
        authorized_ranks.can_demote?(1000, 10, 0).should(be_false)
      end
    end

    describe "#can_ranksay?" do
      it "can ranksay as lower rank if that rank can ranksay/ranksay lower" do
        authorized_ranks.can_ranksay?(10, 100, :RanksayLower, :Ranksay).should(be_true)
        authorized_ranks.can_ranksay?(10, 100, :RanksayLower, :RanksayLower).should(be_true)
      end

      it "can ranksay as current rank" do
        authorized_ranks.can_ranksay?(100, 100, :Ranksay, :Ranksay).should(be_true)
      end

      it "can't ranksay as lower rank if that rank can't ranksay/ranksay lower" do
        authorized_ranks.can_ranksay?(10, 100, :RanksayLower).should(be_false)
      end

      it "can't ranksay as lower rank if the rank is of higher value than invoker rank" do
        authorized_ranks.can_ranksay?(1000, 100, :RanksayLower, :Ranksay).should(be_false)
      end

      it "can't ranksay as blacklisted" do
        authorized_ranks.can_ranksay?(-10, 100, :RanksayLower, :Ranksay).should(be_false)
      end
    end

    describe "#rank_names" do
      it "returns the names of all ranks" do
        expected = ["Blacklisted", "User", "Mod", "Admin", "Host"].sort

        authorized_ranks.rank_names.sort.should(eq(expected))
      end

      it "returns the names of all ranks up to a given value and excluding the blacklisted (-10) rank" do
        expected = ["User", "Mod"].sort

        authorized_ranks.rank_names(10).sort.should(eq(expected))
      end
    end

    describe "#ranksay" do
      it "returns rank name without non-ASCII characters and punctuation" do

        authorized_ranks.ranksay("User").should(eq("user"))
        authorized_ranks.ranksay("Restricted_user").should(eq("restricted_user"))
        authorized_ranks.ranksay("An ordinary user :)").should(eq("an_ordinary_user_"))
        authorized_ranks.ranksay("User オオカミ, *restricted* ").should(eq("user_restricted_"))
        authorized_ranks.ranksay("オオカミ").should(eq(""))
      end
    end
  end
end
