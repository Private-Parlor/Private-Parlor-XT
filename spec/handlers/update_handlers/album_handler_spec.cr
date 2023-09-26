require "../../spec_helper.cr"

module PrivateParlorXT
  describe AlbumHandler do
    client = MockClient.new

    services = create_services(client: client)

    handler = AlbumHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#spamming?" do
      it "returns true if user is spamming albums" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(
          client: client,
          spam: SpamHandler.new(
            spam_limit: 10, score_media_group: 6
          )
        )

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services)

        unless spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not spamming albums" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new)

        handler.spamming?(beispiel, message, spam_services).should(be_false)
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

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
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

        spam_services = create_services(
          client: client,
          spam: SpamHandler.new(
            spam_limit: 10, score_media_group: 6
          )
        )

        unless spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_false)
        handler.spamming?(beispiel, message, spam_services).should(be_false)
      end
    end
  end
end
