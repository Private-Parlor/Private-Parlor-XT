require "../../spec_helper.cr"

module PrivateParlorXT
  describe RegularForwardHandler do
    client = MockClient.new

    ranks = {
      10 => Rank.new(
        "Mod",
        Set(CommandPermissions).new,
        Set{
          MessagePermissions::Forward,
        },
      ),
      -5 => Rank.new(
        "Restricted",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    services = create_services(ranks: ranks, relay: MockRelay.new("", client))

    handler = RegularForwardHandler.new(MockConfig.new)

    around_each do |test|
      services = create_services(ranks: ranks, relay: MockRelay.new("", client))

      generate_users(services.database)
      generate_history(services.history)

      test.run

      services.database.close
    end

    describe "#do" do
      it "returns early if user is not authorized" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          video: Tourmaline::Video.new(
            "video_item_one",
            "unique_video",
            1080,
            1080,
            60,
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user")
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(-5)
        services.database.update_user(user)

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should_not(eq("video_item_one"))
      end

      it "queues regular forward text message" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Forwarded from other user\n\nExample Text"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues regular forward animation message" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("animation_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues regular forward audio message" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          audio: Tourmaline::Audio.new(
            "audio_item_one",
            "unique_audio",
            60,
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("audio_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues regular forward document" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          document: Tourmaline::Document.new(
            "document_item_one",
            "unique_document",
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("document_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues regular forward video message" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          video: Tourmaline::Video.new(
            "video_item_one",
            "unique_video",
            1080,
            1080,
            60,
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("video_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues regular forward photo" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ],
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("photo_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues a forward of a sticker" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          sticker: Tourmaline::Sticker.new(
            "sticker_item_one",
            "unique_sticker",
            "regular",
            1080,
            1080,
            false,
            false,
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("11"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end

      it "queues forward of video message when message was regularly forwarded" do
        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          video: Tourmaline::Video.new(
            "video_item_one",
            "unique_video",
            1080,
            1080,
            60,
          ),
          forward_date: Time.utc,
          forward_from: Tourmaline::User.new(123456, false, "other user"),
          caption: "Forwarded from other user",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              25,
            ),
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        ctx = create_context(client, create_update(11, message))

        handler.do(ctx, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin_msid.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("11"))
          msg.reply_to.should(be_nil)

          [
            80300,
            20000,
            60200,
            50000,
          ].should(contain(msg.receiver))

          [
            70000,
            40000,
          ].should_not(contain(msg.receiver))
        end
      end
    end

    describe "#spamming?" do
      it "returns true if user is spamming forwards" do
        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(client: client, spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

        unless spam = spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services)

        unless spam.scores[beispiel.id]?
          fail("Score for user 80300 should not be nil")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_true)
      end

      it "returns false if user is not spamming forwards" do
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

        spam_services = create_services(client: client, spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

        unless spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_false)
        handler.spamming?(beispiel, message, spam_services).should(be_false)
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

        user = MockUser.new(9000, rank: 0)

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

        user = MockUser.new(9000, rank: 0)

        handler.deanonymous_poll(user, message, services).should(be_false)
      end

      it "returns false if forward does not contain a poll" do
        message = create_message(
          11,
          Tourmaline::User.new(9000, false, "test"),
        )

        user = MockUser.new(9000, rank: 0)

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
