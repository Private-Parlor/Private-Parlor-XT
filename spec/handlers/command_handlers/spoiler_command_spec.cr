require "../../spec_helper.cr"

module PrivateParlorXT
  describe SpoilerCommand do
    ranks = {
      10 => Rank.new(
        "Mod",
        Set{
          CommandPermissions::Spoiler,
        },
        Set(MessagePermissions).new,
      ),
      0 => Rank.new(
        "User",
        Set(CommandPermissions).new,
        Set(MessagePermissions).new,
      ),
    }

    describe "#do" do
      it "returns early if user is not authorized" do
        services = create_services(ranks: ranks)

        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        tourmaline_user = Tourmaline::User.new(20000, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          text: "/spoiler",
          reply_to_message: reply,
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))

        messages[0].data.should(eq(services.replies.command_disabled))
      end

      it "returns early if message has no reply" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.no_reply))
      end

      it "returns early if reply message is a forward" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
          from: bot_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.fail))
      end

      it "returns early with 'not in cache' response if reply message does not exist in message history" do 
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 50,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.not_in_cache))
      end

      it "returns early if user attempts to spoil own message" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.fail))
      end

      it "returns early if InputMedia could not be created from reply message" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          document: Tourmaline::Document.new(
            file_id: "document_item_one",
            file_unique_id: "unique_document",
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.fail))
      end

      it "updates user activity" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        unless updated_user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        user.last_active.should(be < updated_user.last_active)
      end

      it "spoils a message without a spoiler" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(4))

        messages.each do |msg|
          if msg.data != services.replies.success
            msg.data.should(eq(
              "animation_item_one;animation;;true")
            )
          else
            msg.data.should(eq(services.replies.success))
          end
        end
      end

      it "unspoils a message with a spoiler" do
        services = create_services(ranks: ranks)
        
        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        bot_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
          caption: "Animation with a caption",
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          has_media_spoiler: true
        )

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "/spoiler",
          reply_to_message: reply,
          from: tourmaline_user
        )

        handler.do(message, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(4))

        messages.each do |msg|
          if msg.data != services.replies.success
            msg.data.should(eq(
              "animation_item_one;animation;Animation with a caption;")
            )
          else
            msg.data.should(eq(services.replies.success))
          end
        end
      end
    end

    describe "#message_input" do
      it "returns InputMediaPhoto when message contains a photo" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 1,
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
          caption: "Photo caption",
          caption_entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless input = handler.message_input(message)
          fail("message_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaPhoto)
          fail("Input should be an InputMediaPhoto")
        end

        input.caption_entities.size.should(eq(1))
        input.caption_entities[0].type.should(eq("bold"))
        input.caption_entities[0].offset.should(eq(0))
        input.caption_entities[0].length.should(eq(10))

        input.media.should(eq("photo_item_one"))

        input.caption.should(eq("Photo caption"))
      end

      it "returns InputMediaVideo when message contains a video" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 1,
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
          caption: "Video caption",
          caption_entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless input = handler.message_input(message)
          fail("message_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaVideo)
          fail("Input should be an InputMediaVideo")
        end

        input.caption_entities.size.should(eq(1))
        input.caption_entities[0].type.should(eq("bold"))
        input.caption_entities[0].offset.should(eq(0))
        input.caption_entities[0].length.should(eq(10))

        input.media.should(eq("video_item_one"))

        input.caption.should(eq("Video caption"))
      end

      it "returns InputMediaAnimation when message contains an animation" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 1,
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
          caption: "Animation caption",
          caption_entities: [
            Tourmaline::MessageEntity.new(
              type: "bold",
              offset: 0,
              length: 10,
            ),
          ]
        )

        unless input = handler.message_input(message)
          fail("message_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaAnimation)
          fail("Input should be an InputMediaAnimation")
        end

        input.caption_entities.size.should(eq(1))
        input.caption_entities[0].type.should(eq("bold"))
        input.caption_entities[0].offset.should(eq(0))
        input.caption_entities[0].length.should(eq(10))

        input.media.should(eq("animation_item_one"))

        input.caption.should(eq("Animation caption"))
      end

      it "returns nil when message contains a type that can't have a spoiler" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        document_message = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          document: Tourmaline::Document.new(
            file_id: "document_item_one",
            file_unique_id: "unique_document",
          ),
        )

        audio_tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        audio_message = Tourmaline::Message.new(
          message_id: 1,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          audio: Tourmaline::Audio.new(
            file_id: "audio_item_one",
            file_unique_id: "unique_audio",
            duration: 60,
          ),
        )

        handler.message_input(document_message).should(be_nil)
        handler.message_input(audio_message).should(be_nil)
      end
    end

    describe "#spoil_messages" do
      it "returns early if message does not exist in cache" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Animation Caption",
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        input = Tourmaline::InputMediaAnimation.new(
          media: "animation_item_one",
          caption: "Animation Caption",
        )

        handler.spoil_messages(reply, user, input, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(0))
      end

      it "spoils a message without a spoiler" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Animation Caption",
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          has_media_spoiler: false
        )

        input = Tourmaline::InputMediaAnimation.new(
          media: "animation_item_one",
          caption: "Animation Caption",
        )

        handler.spoil_messages(reply, user, input, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(3))

        messages.each do |msg|
          msg.data.should(eq(
            "animation_item_one;animation;Animation Caption;true")
          )
        end
      end

      it "unspoils a message with a spoiler" do
        services = create_services()

        handler = SpoilerCommand.new(MockConfig.new)

        generate_users(services.database)
        generate_history(services.history)

        unless user = services.database.get_user(80300)
          fail("User 80300 should exist in the database")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        reply = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Animation Caption",
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
          has_media_spoiler: true
        )

        input = Tourmaline::InputMediaAnimation.new(
          media: "animation_item_one",
          caption: "Animation Caption",
        )

        handler.spoil_messages(reply, user, input, services)

        messages = services.relay.as(MockRelay).empty_queue
        messages.size.should(eq(3))

        messages.each do |msg|
          msg.data.should(eq(
            "animation_item_one;animation;Animation Caption;")
          )
        end
      end
    end
  end
end
