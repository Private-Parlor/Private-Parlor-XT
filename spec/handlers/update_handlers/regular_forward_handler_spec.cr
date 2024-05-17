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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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
        )

        handler = RegularForwardHandler.new(MockConfig.new)
        
        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.karma.should(eq(-20))

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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
        )

        handler = RegularForwardHandler.new(MockConfig.new)
        
        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        spammy_message = Tourmaline::Message.new(
          message_id: 20,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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
        )

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        unoriginal_message = Tourmaline::Message.new(
          message_id: 20,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
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

        result = stats.message_counts

        result[Statistics::Messages::Forwards].should(eq(1))
        result[Statistics::Messages::TotalMessages].should(eq(1))
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("Forwarded from other user\n\nExample Text"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
          media_group_id: "album_one"
        )

        handler.do(message, services)

        handler.albums["album_one"].should_not(be_nil)
      end

      it "queues regular forward animation message" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("animation_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          audio: Tourmaline::Audio.new(
            file_id: "audio_item_one",
            file_unique_id: "unique_audio",
            duration: 60,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("audio_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          document: Tourmaline::Document.new(
            file_id: "document_item_one",
            file_unique_id: "unique_document",
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("document_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("video_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ],
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("photo_item_one"))
          msg.entities.size.should(eq(3))
          msg.entities[2].type.should(eq("underline"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          sticker: Tourmaline::Sticker.new(
            file_id: "sticker_item_one",
            file_unique_id: "unique_sticker",
            type: "regular",
            width: 1080,
            height: 1080,
            is_animated: false,
            is_video: false,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          entities: [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("11"))
          msg.reply.should(be_nil)

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
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        generate_users(services.database)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
          ),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          caption: "Forwarded from other user",
          entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 25,
            ),
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 7,
            ),
          ],
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(4))

        messages.each do |msg|
          msg.origin.should(eq(11))
          msg.sender.should(eq(80300))
          msg.data.should(eq("11"))
          msg.reply.should(be_nil)

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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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
            media: "album_item_one",
          )
        )
        handler.albums.merge!({"album_one" => album})

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

    describe "#deanonymous_poll?" do
      it "returns true if forward contains a deanonymous poll" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)
    
        tourmaline_user = Tourmaline::User.new(9000, false, "test")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        handler.deanonymous_poll?(user, message, services).should(be_true)
      end

      it "returns false if forward contains an anonymous poll" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(9000, false, "test")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        handler.deanonymous_poll?(user, message, services).should(be_false)
      end

      it "returns false if forward does not contain a poll" do
        services = create_services(ranks: ranks)

        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(9000, false, "test")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        user = MockUser.new(9000, rank: 0)

        handler.deanonymous_poll?(user, message, services).should(be_false)
      end
    end

    describe "#get_header" do
      it "returns empty header and empty entities if message without caption is part of a queued album" do
        handler = RegularForwardHandler.new(MockConfig.new)

        album = AlbumHelpers::Album.new(
          1_i64,
          Tourmaline::InputMediaPhoto.new(
            media: "album_item_one",
          )
        )
        handler.albums.merge!({"album_one" => album})

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          media_group_id: "album_one"
        )

        tuple = handler.get_header(message, [] of Tourmaline::MessageEntity)

        tuple.should(eq({"", [] of Tourmaline::MessageEntity}))
      end
    end

    describe "#sufficient_karma?" do
      it "returns true if there is no karma economy handler" do
        services = create_services()

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if price for forwarded messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_forwarded_message: -10))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user's rank is equal to or greater than the cutoff rank" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 10,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
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
          Tourmaline::InputMediaPhoto.new(media: "")
        )

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 12,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          media_group_id: "album_one"
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns true if user has sufficient karma" do
        services = create_services(karma_economy: KarmaHandler.new(
          cutoff_rank: 100,
          karma_forwarded_message: 10,
        ))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_true)
      end

      it "returns nil and queues 'insufficient karma' response if user does not have enough karma" do
        services = create_services(
          karma_economy: KarmaHandler.new(
            cutoff_rank: 100,
            karma_forwarded_message: 10,
          )
        )

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, rank: 10, karma: 9)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        handler.sufficient_karma?(user, message, services).should(be_nil)

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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(10))
      end

      it "returns unaltered user if price of forwarded messages is less than 0" do
        services = create_services(karma_economy: KarmaHandler.new(karma_forwarded_message: -10))

        handler = RegularForwardHandler.new(MockConfig.new)

        user = MockUser.new(9000, karma: 10)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          media_group_id: "album_one"
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(0))

        handler.albums["album_one"] = AlbumHelpers::Album.new(
          11, 
          Tourmaline::InputMediaPhoto.new(media: "")
        )

        message_two = Tourmaline::Message.new(
          message_id: 12,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          date: Time.utc,
          from: tourmaline_user,
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

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
        )

        result = handler.spend_karma(user, message, services)

        result.karma.should(eq(0))
      end
    end

    describe "#regular_forward?" do
      it "returns true if message is a regular forward" do
        handler = RegularForwardHandler.new(MockConfig.new)

        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "bold",
            offset: 0,
            length: 19,
          ),
        ]

        handler.regular_forward?(text, entities).should(be_true)
      end

      it "returns false if message is not a regular forward" do
        handler = RegularForwardHandler.new(MockConfig.new)

        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "italic",
            offset: 0,
            length: 19,
          ),
        ]

        handler.regular_forward?(text, entities).should(be_false)
      end

      it "returns nil if given no entities" do
        handler = RegularForwardHandler.new(MockConfig.new)

        text = "Forwarded from User"

        handler.regular_forward?(text, [] of Tourmaline::MessageEntity).should(be_nil)
      end

      it "returns nil if given no text" do
        handler = RegularForwardHandler.new(MockConfig.new)
        
        handler.regular_forward?(nil, [] of Tourmaline::MessageEntity).should(be_nil)
      end
    end

    describe "#forward_header" do
      it "returns header and entities for forwards from users with public forwards" do
        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(
              9000,
              is_bot: false,
              first_name: "example",
              last_name: nil,
            )
          )
        )

        header, entities = handler.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from example\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(22))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(7))
        entities[1].url.should(eq("tg://user?id=9000"))
      end

      it "returns header and entities for forwards from Telegram bots" do
        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(
              9000,
              is_bot: true,
              first_name: "ExampleBot",
              last_name: nil,
              username: "example_bot"
            )
          )
        )

        header, entities = handler.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from ExampleBot\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(25))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(10))
        entities[1].url.should(eq("tg://resolve?domain=example_bot"))
      end

      it "returns header and entities for forwards from public channels" do
        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginChannel.new(
            "channel",
            Time.utc,
            Tourmaline::Chat.new(
              9000,
              type: "channel",
              title: "Example Channel",
              username: "ExamplesChannel"
            ),
            200_i64,
          )
        )

        header, entities = handler.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Example Channel\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(30))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(15))
        entities[1].url.should(eq("tg://resolve?domain=ExamplesChannel&post=200"))
      end

      it "returns header and entities for forwards from private channels" do
        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginChannel.new(
            "channel",
            Time.utc,
            Tourmaline::Chat.new(
              -1009000,
              type: "private",
              title: "Private Example Channel",
            ),
            200_i64,
          )
        )

        header, entities = handler.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private Example Channel\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(38))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(23))
        entities[1].url.should(eq("tg://privatepost?channel=9000&post=200"))
      end

      it "returns header and entities in italics for forwards from users with private forwards" do
        handler = RegularForwardHandler.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 100,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          forward_origin: Tourmaline::MessageOriginHiddenUser.new(
            "hidden_user",
            Time.utc,
            "Private User"
          )
        )

        header, entities = handler.forward_header(message, [] of Tourmaline::MessageEntity)

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private User\n\n"))

        entities.size.should(eq(2))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(27))

        entities[1].type.should(eq("italic"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(12))
      end
    end

    describe "#user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        handler = RegularForwardHandler.new(MockConfig.new)

        header, entities = handler.user_forward(
          "Dodo 🦤🏝🍽",
          9000,
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Dodo 🦤🏝🍽\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(26))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(11))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(28))
        entities[2].length.should(eq(10))
      end
    end

    describe "#private_user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        handler = RegularForwardHandler.new(MockConfig.new)

        header, entities = handler.private_user_forward(
          "Private 🔒🦤 Dodo",
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from Private 🔒🦤 Dodo\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(32))

        entities[1].type.should(eq("italic"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(17))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(34))
        entities[2].length.should(eq(10))
      end
    end

    describe "#username_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        handler = RegularForwardHandler.new(MockConfig.new)

        header, entities = handler.username_forward(
          "🤖 Dodo Bot 🦤",
          "dodobot",
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from 🤖 Dodo Bot 🦤\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(29))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(14))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(31))
        entities[2].length.should(eq(10))
      end
    end

    describe "#private_channel_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        handler = RegularForwardHandler.new(MockConfig.new)

        header, entities = handler.private_channel_forward(
          "🦤 Private 🔒 Dodo 📣",
          9000,
          [
            Tourmaline::MessageEntity.new(
              type: "underline",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless header
          fail("Header should not be nil")
        end

        header.should(eq("Forwarded from 🦤 Private 🔒 Dodo 📣\n\n"))

        entities.size.should(eq(3))
        entities[0].type.should(eq("bold"))
        entities[0].offset.should(eq(0))
        entities[0].length.should(eq(36))

        entities[1].type.should(eq("text_link"))
        entities[1].offset.should(eq(15))
        entities[1].length.should(eq(21))

        entities[2].type.should(eq("underline"))
        entities[2].offset.should(eq(38))
        entities[2].length.should(eq(10))
      end
    end
  end
end
