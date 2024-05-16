require "../spec_helper.cr"

module PrivateParlorXT
  describe SQLiteDatabase, tags: "database" do
    connection = DB.open("sqlite3://%3Amemory%3A")
    db = SQLiteDatabase.new(connection)

    around_each do |test|
      connection = DB.open("sqlite3://%3Amemory%3A")
      db = SQLiteDatabase.new(connection)

      # Add users
      connection.exec("INSERT INTO users VALUES (20000,'examp','example',1000,'2023-01-02 06:00:00.000',NULL,'2023-07-02 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")
      connection.exec("INSERT INTO users VALUES (60200,'voorb','voorbeeld',0,'2023-01-02 06:00:00.000',NULL,'2023-01-02 06:00:00.000',NULL,NULL,1,'2023-03-02 12:00:00.000',-10,0,0,NULL);")
      connection.exec("INSERT INTO users VALUES (80300,NULL,'beispiel',10,'2023-01-02 06:00:00.000',NULL,'2023-03-02 12:00:00.000',NULL,NULL,2,'2023-04-02 12:00:00.000',-20,0,1,NULL);")
      connection.exec("INSERT INTO users VALUES (40000,NULL,'esimerkki',0,'2023-01-02 06:00:00.000','2023-02-04 06:00:00.000','2023-02-04 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")
      connection.exec("INSERT INTO users VALUES (70000,NULL,'BLACKLISTED',-10,'2023-01-02 06:00:00.000','2023-04-02 10:00:00.000','2023-01-02 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")

      test.run

      db.close
    end

    describe "#get_user" do
      it "returns a User object if the user exists" do
        user = db.get_user(80300)

        unless user
          fail("User ID 80300 should exist in the database")
        end

        user.id.should(eq(80300))
      end

      it "returns nil if the user does not exist" do
        db.get_user(12345).should(be_nil)
      end
    end

    describe "#get_user_counts" do
      it "returns total number of users, inactive, and blacklisted" do
        tuple = db.get_user_counts

        tuple[:total].should(eq(5))
        tuple[:left].should(eq(2))
        tuple[:blacklisted].should(eq(1))
      end
    end

    describe "#get_blacklisted_users" do
      it "returns all blacklisted users" do
        users = db.get_blacklisted_users

        users[0].id.should(eq(70000))
      end

      it "returns users blacklisted recently" do
        new_user = db.add_user(12345, nil, "BLACKLISTED", -10)
        new_user.set_left
        db.update_user(new_user)

        users = db.get_blacklisted_users(1.hours)

        users[0].id.should(eq(new_user.id))
      end
    end

    describe "#get_warned_users" do
      it "returns all warned users" do
        users = db.get_warned_users

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
      end
    end

    describe "#get_invalid_rank_users" do
      it "returns all users with invalid ranks" do
        users = db.get_invalid_rank_users([1000, 0, -10])

        users[0].rank.should(eq(10))
        users[0].id.should(eq(80300))
      end
    end

    describe "#get_inactive_users" do
      it "returns all inactive users" do
        db.add_user(12345, "", "Active", 0)

        users = db.get_inactive_users(1.days)

        users.size.should(eq(3))
      end
    end

    describe "#get_user_by_name" do
      it "returns a user with the given name" do
        user = db.get_user_by_name("voorb")

        unless user
          fail("User ID 60200 should have been found by name")
        end

        user.id.should(eq(60200))
      end

      it "returns nil if the user does not exist" do
        user = db.get_user_by_name("beisp")

        user.should(be_nil)
      end
    end

    describe "#get_user_by_oid" do
      it "returns a user with the given OID" do
        oid = MockUser.new(20000).get_obfuscated_id

        user = db.get_user_by_oid(oid)

        unless user
          fail("User ID 20000 should have been found by OID")
        end

        user.id.should(eq(20000))
      end

      it "returns nil if the user does not exist" do
        oid = MockUser.new(12345).get_obfuscated_id

        user = db.get_user_by_oid(oid)

        user.should(be_nil)
      end
    end

    describe "#get_user_by_arg" do
      it "returns a user with the id" do
        user = db.get_user_by_arg("20000")

        unless user
          fail("User ID 20000 should have been found by ID")
        end

        user.id.should(eq(20000))
      end

      it "returns a user with the oid" do
        oid = MockUser.new(20000).get_obfuscated_id

        user = db.get_user_by_arg(oid)

        unless user
          fail("User ID 20000 should have been found by OID")
        end

        user.id.should(eq(20000))
      end

      it "returns a user with the name" do
        user = db.get_user_by_arg("@examp")

        unless user
          fail("User ID 20000 should have been found by username")
        end

        user.id.should(eq(20000))
      end
    end

    describe "#get_active_users" do
      it "returns recently active users, ordered first by rank" do
        arr = db.get_active_users

        arr[0].should(eq(20000))
        arr[1].should(eq(80300))
        arr[2].should(eq(60200))
      end

      it "excludes user from result if given a user ID" do
        arr = db.get_active_users(exclude: 80300)

        arr[0].should(eq(20000))
        arr[1].should(eq(60200))
      end
    end

    describe "#add_user" do
      it "returns new user after adding to the database" do
        new_user = db.add_user(12345, nil, "NewUser", 0)

        new_user.should(be_a(SQLiteUser))

        new_user.id.should(eq(12345))
      end
    end

    describe "#update_user" do
      it "updates user with new data" do
        user = MockUser.new(20000)
        user.update_names("examp", "EXAMP")

        db.update_user(user)

        updated_user = db.get_user(20000)

        unless updated_user
          fail("A user with ID 20000 should exist in the database")
        end

        updated_user.realname.should(eq("EXAMP"))
      end
    end

    describe "#no_users?" do
      it "returns true if there are no users in the database" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        connection.exec("DROP TABLE IF EXISTS USERS")

        db = SQLiteDatabase.new(connection)

        db.no_users?.should(be_true)
      end

      it "returns false if the database contains users" do
        db.no_users?.should(be_false)
      end
    end

    describe "#expire_warnings" do
      it "removes warnings and updates warn expiration date" do
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
      end
    end

    describe "#set_motd" do
      it "updates the MOTD with the given value" do
        db.set_motd("An updated *MOTD*")

        motd = db.get_motd

        unless motd
          fail("MOTD should not have been nil")
        end

        motd.should(eq("An updated *MOTD*"))
      end
    end

    describe "#get_motd" do
      it "returns nil if there is no MOTD" do
        motd = db.get_motd

        motd.should(be_nil)
      end
    end

    it "returns the MOTD if set" do
      db.set_motd("test")

      motd = db.get_motd

      unless motd
        fail("MOTD should not have been nil")
      end

      motd.should(eq("test"))
    end
  end
end
