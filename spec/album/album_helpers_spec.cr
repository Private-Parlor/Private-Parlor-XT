require "../spec_helper.cr"

module PrivateParlorXT

  # NOTE: Can't test relay_album due to its delayed task

  module AlbumHelpers
    extend self
  end

  describe AlbumHelpers do
    describe "#get_album_input" do
      it "returns InputMediaPhoto when message contains a photo" do
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 1,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
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
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 1,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
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
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 1,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          audio: Tourmaline::Audio.new(
            file_id: "audio_item_one",
            file_unique_id: "unique_audio",
            duration: 60,
          ),
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
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 1,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          document: Tourmaline::Document.new(
            file_id: "document_item_one",
            file_unique_id: "unique_document",
          ),
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
        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = create_message(
          message_id: 1,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          from: tourmaline_user,
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        input = AlbumHelpers.get_album_input(message, "animation caption", [] of Tourmaline::MessageEntity, true)

        input.should(be_nil)
      end
    end
  end
end
