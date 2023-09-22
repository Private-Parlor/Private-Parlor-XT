require "../../spec_helper.cr"

module PrivateParlorXT
  describe RegularForwardHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = RegularForwardHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#is_spamming?" do
      it "returns true if user is spamming forwards" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end
        
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        ctx = create_context(client, create_update(11, message))
        spam_services = create_services(client: client, spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.is_spamming?(beispiel, message, spam_services)

        unless score = spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.is_spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not spamming forwards" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new())

        handler.is_spamming?(beispiel, message, services).should(be_false)
      end

      it "returns false if no spam handler" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spamless_services = create_services(client: client)

        handler.is_spamming?(beispiel, message, spamless_services).should(be_false)
      end

      it "returns false if message is part of a queued album" do
        unless beispiel = services.database.get_user(80300) 
          fail("User 80300 should exist in the database")
        end

        album = AlbumHelpers::Album.new(
          1_i64, 
          Tourmaline::InputMediaPhoto.new(
            "album_item_one",
          )
        )
        handler.albums.merge!({"album_one" => album})

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          media_group_id: "album_one"
        )

        ctx = create_context(client, create_update(11, message))
        spam_services = create_services(client: client, spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.is_spamming?(beispiel, message, spam_services).should(be_false)
        handler.is_spamming?(beispiel, message, spam_services).should(be_false)
      end
    end

    describe "#deanonymous_poll" do
      it "returns true if forward contains a deanonymous poll" do
        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "test"),
          poll: Tourmaline::Poll.new(
            id: "poll_id",
            question: "Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: false,
            type: "regular",
            allows_multiple_answers: false,
          )
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.deanonymous_poll(user, message, services).should(be_true)
      end

      it "returns false if forward contains an anonymous poll" do
        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "test"),
          poll: Tourmaline::Poll.new(
            id: "poll_id",
            question: "Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: true,
            type: "regular",
            allows_multiple_answers: false,
          )
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.deanonymous_poll(user, message, services).should(be_false)
      end

      it "returns false if forward does not contain a poll" do
        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "test"),
        )

        user = SQLiteUser.new(9000, rank: 0)

        handler.deanonymous_poll(user, message, services).should(be_false)
      end
    end

    describe "#get_header" do
      it "returns empty header and empty entities if message without caption is part of a queued album" do
        album = AlbumHelpers::Album.new(
          1_i64, 
          Tourmaline::InputMediaPhoto.new(
            "album_item_one",
          )
        )
        handler.albums.merge!({"album_one" => album})

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          media_group_id: "album_one"
        )

        tuple = handler.get_header(message, [] of Tourmaline::MessageEntity)

        tuple.should(eq({"", [] of Tourmaline::MessageEntity}))
      end
    end
  end
end