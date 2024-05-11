require "../../spec_helper.cr"

module PrivateParlorXT
  describe RegularForwardHandler do
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

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.set_rank(-5)
        services.database.update_user(user)

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should_not(eq("video_item_one"))
      end

      
      it "returns early with 'deanonymous poll' response if forwaded poll does not have anonymous voting" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          poll: Tourmaline::Poll.new(
            id: "poll_id",
            question: "Question",
            total_voter_count: 0,
            is_closed: false,
            is_anonymous: false,
            type: "regular",
            allows_multiple_answers: false,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.deanon_poll))
      end

      it "returns early with 'insufficient karma' response if KarmaHandler is enabled and user does not have sufficient karma" do
        services = create_services(
          ranks: ranks, 
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_forwarded_message: 10,
          ),
          relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)
        
        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        handler.do(message, services)

        expected = Format.substitute_reply(services.replies.insufficient_karma, {
          "amount" => 10.to_s,
          "type" => "forward"
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "returns early with 'spamming' response if user is spamming" do
        services = create_services(
          ranks: ranks, 
          spam: SpamHandler.new(
            spam_limit: 10, score_forwarded_message: 6
          ),
          relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)
        
        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        spammy_message = create_message(
          20,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        handler.do(spammy_message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.spamming))
      end

      it "returns early with 'unoriginal message' response if Robot9000 is enabled and message is not unique" do
        services = create_services(
          ranks: ranks, 
          r9k: SQLiteRobot9000.new(
            DB.open("sqlite3://%3Amemory%3A"),
            check_text: true,
            check_forwards: true,
          ),
          relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))
        messages[0].data.should(eq("Forwarded from other user\n\nExample Text"))

        unoriginal_message = create_message(
          20,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        handler.do(unoriginal_message, services)
        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.unoriginal_message))
      end

      it "records message statistics when statitics is enabled" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)
        
        services = create_services(
          ranks: ranks,
          database: database,
          statistics: SQLiteStatistics.new(connection),
        )

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.do(message, services)

        unless stats = services.stats
          fail("Services should have a statistics object")
        end

        result = stats.get_total_messages

        result[Statistics::MessageCounts::Forwards].should(eq(1))
        result[Statistics::MessageCounts::TotalMessages].should(eq(1))
      end

      it "spends user karma when KarmaHandler is enabled" do
        services = create_services(
          ranks: ranks, 
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_forwarded_message: 10,
          )
        )

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))
        user.increment_karma(30)
        services.database.update_user(user)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        updated_user.karma.should(eq(0))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          )
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "queues regular forward text message" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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

      it "queues regular forward album message" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
          media_group_id: "album_one"
        )

        handler.do(message, services)

        handler.albums["album_one"].should_not(be_nil)
      end

      it "queues regular forward animation message" do
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          audio: Tourmaline::Audio.new(
            "audio_item_one",
            "unique_audio",
            60,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          document: Tourmaline::Document.new(
            "document_item_one",
            "unique_document",
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              "underline",
              0,
              7,
            ),
          ],
        )

        handler.do(message, services)

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
        services = create_services(ranks: ranks, relay: MockRelay.new("", MockClient.new))

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
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

        handler.do(message, services)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spam_services = create_services(spam: SpamHandler.new)

        handler.spamming?(beispiel, message, spam_services).should(be_false)
      end

      it "returns false if no spam handler" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        unless beispiel = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        spamless_services = create_services()

        handler.spamming?(beispiel, message, spamless_services).should(be_false)
      end

      it "returns false if message is part of a queued album" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

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

        spam_services = create_services(spam: SpamHandler.new(spam_limit: 10, score_forwarded_message: 6))

        unless spam_services.spam
          fail("Services should contain a spam handler")
        end

        handler.spamming?(beispiel, message, spam_services).should(be_false)
        handler.spamming?(beispiel, message, spam_services).should(be_false)
      end
    end

    describe "#deanonymous_poll" do
      it "returns true if forward contains a deanonymous poll" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)
    
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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

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
        handler = RegularForwardHandler.new(MockConfig.new)

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

    describe "#has_sufficient_karma?" do
      it "returns true if there is no karma economy handler" do
        services = create_services()

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.has_sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if price for forwarded messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_forwarded_message: -10))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.has_sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.has_sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if message is part of a queued album" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 9)

        handler.albums["album_one"] = AlbumHelpers::Album.new(
          11, 
          Tourmaline::InputMediaPhoto.new("")
        )

        message = create_message(
          12,
          Tourmaline::User.new(80300, false, "beispiel"),
          media_group_id: "album_one"
        )

        handler.has_sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user has sufficient karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.has_sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns nil and queues 'insufficient karma' response if user does not have enough karma" do
        services = create_services(
          relay: MockRelay.new("", MockClient.new), 
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_forwarded_message: 10,
          )
        )

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 9)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        handler.has_sufficient_karma?(user, message, services).should(be_nil)

        expected = Format.substitute_reply(services.replies.insufficient_karma, {
          "amount" => 10.to_s,
          "type" => "forward"
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end
    end

    describe "#spend_karma" do
      it "returns unaltered user if there is no karma economy handler" do
        services = create_services()

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if price of forwarded messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_forwarded_message: -10))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if message is part of an already queued album" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          media_group_id: "album_one"
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(0))

        handler.albums["album_one"] = AlbumHelpers::Album.new(
          11, 
          Tourmaline::InputMediaPhoto.new("")
        )

        message_two = create_message(
          12,
          Tourmaline::User.new(80300, false, "beispiel"),
          media_group_id: "album_one"
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(0))
      end

      it "returns user with decremented karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(0))
      end
    end
  end
end
