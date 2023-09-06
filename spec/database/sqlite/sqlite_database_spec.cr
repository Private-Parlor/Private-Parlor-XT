require "../../spec_helper.cr"

module PrivateParlorXT

  describe SQLiteDatabase, tags: "database" do
    # TODO: Ideally these tests would do something smarter than re-creating 
    # the same database over and over
    around_each do |example|
      create_sqlite_database
      example.run
      delete_sqlite_database
    end

    describe "#get_user" do
      it "returns a User object if the user exists" do
        db = instantiate_sqlite_database

        user = db.get_user(80300)

        unless user
          fail("User ID 80300 should exist in the database")
        end
      
        user.id.should(eq(80300))

        db.close
      end

      it "returns nil if the user does not exist" do
        db = instantiate_sqlite_database
        
        db.get_user(12345).should(be_nil)

        db.close
      end
    end

    describe "#get_user_counts" do
      it "returns total number of users, inactive, and blacklisted" do
        db = instantiate_sqlite_database

        tuple = db.get_user_counts

        tuple[:total].should(eq(5))
        tuple[:left].should(eq(2))
        tuple[:blacklisted].should(eq(1))

        db.close
      end
    end

    describe "#get_blacklisted_users" do
      it "returns all blacklisted users" do
        db = instantiate_sqlite_database

        users = db.get_blacklisted_users()

        users[0].id.should(eq(70000))

        db.close
      end

      it "returns users blacklisted recently", do
        db = instantiate_sqlite_database

        new_user = db.add_user(12345, nil, "BLACKLISTED", -10)
        new_user.set_left
        db.update_user(new_user)

        users = db.get_blacklisted_users(1.hours)

        users[0].id.should(eq(new_user.id))

        db.close
      end
    end

    describe "#get_warned_users" do
      it "returns all warned users" do
        db = instantiate_sqlite_database
        
        users = db.get_warned_users()

        if users.size > 2
          fail("There should have been only 2 users with warnings")
        end

        users.each do |user|
          if user.id == 60200
            user.warnings.should(eq(1))
          elsif user.id == 80300
            user.warnings.should(eq(2))
          end
        end

        db.close
      end
    end

    describe "#get_invalid_rank_users" do
      it "returns all users with invalid ranks" do
        db = instantiate_sqlite_database
        
        users = db.get_invalid_rank_users([1000, 0, -10])

        users[0].rank.should(eq(10))
        users[0].id.should(eq(80300))

        db.close
      end
    end

    describe "#get_inactive_users" do
      it "returns all inactive users" do
        db = instantiate_sqlite_database

        db.add_user(12345, "", "Active", 0)

        users = db.get_inactive_users(1.days)

        users.size.should(eq(3))

        db.close
      end
    end

    describe "#get_user_by_name" do
      it "returns a user with the given name" do
        db = instantiate_sqlite_database

        user = db.get_user_by_name("voorb")

        unless user
          fail("User ID 60200 should have been found by name")
        end

        user.id.should(eq(60200))

        db.close
      end

      it "returns nil if the user does not exist" do
        db = instantiate_sqlite_database

        user = db.get_user_by_name("beisp")

        user.should(be_nil)

        db.close
      end
    end

    describe "#get_user_by_oid" do
      it "returns a user with the given OID" do
        db = instantiate_sqlite_database

        oid = SQLiteUser.new(20000).get_obfuscated_id

        user = db.get_user_by_oid(oid)

        unless user
          fail("User ID 20000 should have been found by OID")
        end

        user.id.should(eq(20000))

        db.close
      end

      it "returns nil if the user does not exist" do
        db = instantiate_sqlite_database

        oid = SQLiteUser.new(12345).get_obfuscated_id

        user = db.get_user_by_oid(oid)

        user.should(be_nil)

        db.close
      end
    end

    describe "#get_user_by_arg" do
      it "returns a user with the id" do
        db = instantiate_sqlite_database

        user = db.get_user_by_arg("20000")

        unless user
          fail("User ID 20000 should have been found by ID")
        end

        user.id.should(eq(20000))

        db.close
      end

      it "returns a user with the oid" do
        db = instantiate_sqlite_database

        oid = SQLiteUser.new(20000).get_obfuscated_id

        user = db.get_user_by_arg(oid)

        unless user
          fail("User ID 20000 should have been found by OID")
        end

        user.id.should(eq(20000))

        db.close
      end

      it "returns a user with the name" do
        db = instantiate_sqlite_database

        user = db.get_user_by_arg("@examp")

        unless user
          fail("User ID 20000 should have been found by username")
        end

        user.id.should(eq(20000))

        db.close
      end
    end

    describe "#get_active_users" do
      it "returns recently active users, ordered first by rank" do
        db = instantiate_sqlite_database

        arr = db.get_active_users

        arr[0].should(eq(20000))
        arr[1].should(eq(80300))
        arr[2].should(eq(60200))

        db.close
      end

      it "excludes user from result if given a user ID" do
        db = instantiate_sqlite_database

        arr = db.get_active_users(exclude: 80300)
        
        arr[0].should(eq(20000))
        arr[1].should(eq(60200))

        db.close
      end
    end

    describe "#add_user" do
      it "returns new user after adding to the database" do
        db = instantiate_sqlite_database

        new_user = db.add_user(12345, nil, "NewUser", 0)

        new_user.should(be_a(SQLiteUser))

        new_user.id.should(eq(12345))

        db.close
      end
    end

    describe "#update_user" do
      it "updates user with new data" do
        db = instantiate_sqlite_database

        user = SQLiteUser.new(20000)
        user.update_names("examp", "EXAMP")

        db.update_user(user)

        updated_user = db.get_user(20000)

        unless updated_user
          fail("A user with ID 20000 should exist in the database")
        end

        updated_user.realname.should(eq("EXAMP"))

        db.close
      end
    end

    describe "#no_users?" do
      it "returns false if the database contains users" do
        db = instantiate_sqlite_database

        db.no_users?.should(be_false)

        db.close
      end
    end

    describe "#expire_warnings" do
      it "removes warnings and updates warn expiration date" do
        db = instantiate_sqlite_database

        unless user_with_multiple_warnings = db.get_user(80300)
          fail("User ID 803000 should exist in the database")
        end

        original_expiration = user_with_multiple_warnings.warn_expiry

        unless original_expiration
          fail("User ID 80300 should have a warn expiration date already")
        end

        db.expire_warnings(5.days)

        user_voorb = db.get_user(60200)
        user_beisp = db.get_user(80300)

        unless user_voorb && user_beisp
          fail("User ID 60200 and user ID 80300 should exist in the database")
        end

        unless user_beisp.warn_expiry 
          fail("User ID 80300 should still have a warn expiration date")
        end

        user_voorb.warn_expiry.should(be_nil)
        user_voorb.warnings.should(eq(0))

        user_beisp.warn_expiry.should_not(eq(original_expiration))
        user_beisp.warnings.should(eq(1))

        db.close
      end
    end

    describe "#get_motd" do
      it "returns nil if there is no MOTD" do
        db = instantiate_sqlite_database

        motd = db.get_motd

        motd.should(be_nil)

        db.close
      end
    end

    it "returns the MOTD if set" do
      db = instantiate_sqlite_database

      db.set_motd("test")

      motd = db.get_motd

      unless motd
        fail("MOTD should not have been nil")
      end

      motd.should(eq("test"))

      db.close
    end
  end
end