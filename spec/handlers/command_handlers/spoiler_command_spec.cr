require "../../spec_helper.cr"

module PrivateParlorXT
  describe SpoilerCommand do
    client = MockClient.new

    services = create_services(client: client)

    handler = SpoilerCommand.new(MockConfig.new)

    around_each do |test|
      services = create_services(client: client)

      test.run

      services.database.close
    end

    describe "#get_message_input" do
      it "returns InputMediaPhoto when message contains a photo" do
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ],
          caption: "Photo caption",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              10,
            ),
          ]
        )

        unless input = handler.get_message_input(message)
          fail("get_message_input should not have returned nil")
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
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          video: Tourmaline::Video.new(
            "video_item_one",
            "unique_video",
            1080,
            1080,
            60,
          ),
          caption: "Video caption",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              10,
            ),
          ]
        )

        unless input = handler.get_message_input(message)
          fail("get_message_input should not have returned nil")
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
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          animation: Tourmaline::Animation.new(
            "animation_item_one",
            "unique_animation",
            1080,
            1080,
            60,
          ),
          caption: "Animation caption",
          entities: [
            Tourmaline::MessageEntity.new(
              "bold",
              0,
              10,
            ),
          ]
        )

        unless input = handler.get_message_input(message)
          fail("get_message_input should not have returned nil")
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
        document_message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          document: Tourmaline::Document.new(
            "document_item_one",
            "unique_document",
          ),
        )

        audio_message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          audio: Tourmaline::Audio.new(
            "audio_item_one",
            "unique_audio",
            60,
          ),
        )

        handler.get_message_input(document_message).should(be_nil)
        handler.get_message_input(audio_message).should(be_nil)
      end
    end
  end
end
