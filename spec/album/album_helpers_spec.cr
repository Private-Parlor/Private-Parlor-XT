require "../spec_helper.cr"

module PrivateParlorXT
  module AlbumHelpers
    extend self
  end

  describe AlbumHelpers do
    describe "#get_album_input" do
      it "returns InputMediaPhoto when message contains a photo" do
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          photo: [Tourmaline::PhotoSize.new(
            "photo_item_one", 
            "unique_photo",
            1080,
            1080,
            )
          ],
          has_media_spoiler: true
        )

        unless input = AlbumHelpers.get_album_input(message, "photo caption", [] of Tourmaline::MessageEntity, true)
          fail("get_album_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaPhoto)
          fail("Input should be an InputMediaPhoto")
        end

        input.caption.should(eq("photo caption"))
        input.caption_entities.should(eq([] of Tourmaline::MessageEntity))
        input.has_spoiler?.should(be_true)
        input.parse_mode.should(be_nil)
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
          has_media_spoiler: true
        )

        unless input = AlbumHelpers.get_album_input(message, "video caption", [] of Tourmaline::MessageEntity, true)
          fail("get_album_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaVideo)
          fail("Input should be an InputMediaVideo")
        end

        input.caption.should(eq("video caption"))
        input.caption_entities.should(eq([] of Tourmaline::MessageEntity))
        input.has_spoiler?.should(be_true)
        input.parse_mode.should(be_nil)
      end

      it "returns InputMediaAudio when message contains an audio file" do
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          audio: Tourmaline::Audio.new("audio_item_one", "unique_audio", 60),
        )

        unless input = AlbumHelpers.get_album_input(message, "audio caption", [] of Tourmaline::MessageEntity, true)
          fail("get_album_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaAudio)
          fail("Input should be an InputMediaAudio")
        end

        input.caption.should(eq("audio caption"))
        input.caption_entities.should(eq([] of Tourmaline::MessageEntity))
        input.parse_mode.should(be_nil)
      end

      it "returns InputMediaDocument when message contains a document" do
        message = create_message(
          1_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          document: Tourmaline::Document.new("document_item_one", "unique_document"),
        )

        unless input = AlbumHelpers.get_album_input(message, "document caption", [] of Tourmaline::MessageEntity, true)
          fail("get_album_input should not have returned nil")
        end

        unless input.is_a?(Tourmaline::InputMediaDocument)
          fail("Input should be an InputMediaDocument")
        end

        input.caption.should(eq("document caption"))
        input.caption_entities.should(eq([] of Tourmaline::MessageEntity))
        input.parse_mode.should(be_nil)
      end

      it "returns nil when message does not contain a media group type" do
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
        )

        input = AlbumHelpers.get_album_input(message, "animation caption", [] of Tourmaline::MessageEntity, true)
         
        input.should(be_nil)
      end
    end
  end
end