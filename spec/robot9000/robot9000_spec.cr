require "../spec_helper.cr"

module PrivateParlorXT
  describe Robot9000 do
    describe "#remove_links" do
      it "returns text with URLs removed" do
        r9k = MockRobot9000.new

        text = "Example text with 🔗 links:\n" \
               "https://www.google.com\n" \
               "www.example.com"

        entities = [
          Tourmaline::MessageEntity.new(
            type: "url",
            offset: 28,
            length: 22,
          ),
          Tourmaline::MessageEntity.new(
            type: "url",
            offset: 51,
            length: 15,
          ),
        ]

        expected = "Example text with 🔗 links:\n\n"

        stripped_text = r9k.remove_links(text, entities)

        stripped_text.should(eq(expected))
      end
    end

    describe "#allow_text?" do
      it "returns true if text is empty" do
        r9k = MockRobot9000.new

        text = ""

        r9k.allow_text?(text).should(be_true)
      end

      it "returns true if text contains valid codepoints" do
        r9k = MockRobot9000.new

        text = "Example text"

        r9k.allow_text?(text).should(be_true)
      end

      it "returns false if text does not contain valid codepoints" do
        r9k = MockRobot9000.new

        text = "Example text 🦡"

        r9k.allow_text?(text).should(be_false)
      end
    end

    describe "#strip_text" do
      it "strips text of extraneous content" do
        r9k = MockRobot9000.new

        text_one = "An example of text with urls\n" \
                   "www.example.com\n" \
                   "and _NOT MUCH_ else.   "

        url_entity = Tourmaline::MessageEntity.new(
          type: "url",
          offset: 29,
          length: 15,
        )

        text_two = "  A text that references.\n" \
                   "a user @username and a /pin command."

        text_three = "A tttteeeeexxxxttttt   _trying_    *22222* bbbe >>>/foo/ original,"

        expected_one = "an example of text with urls and not much else"
        expected_two = "a text that references a user and a command"
        expected_three = "a text trying 22222 be original"

        r9k.strip_text(text_one, [url_entity]).should(eq(expected_one))
        r9k.strip_text(text_two, [] of Tourmaline::MessageEntity).should(eq(expected_two))
        r9k.strip_text(text_three, [] of Tourmaline::MessageEntity).should(eq(expected_three))
      end
    end

    describe "#get_media_file_id" do
      it "gets unique animation file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          animation: Tourmaline::Animation.new(
            file_id: "animation_item_one",
            file_unique_id: "unique_animation",
            width: 1080,
            height: 1080,
            duration: 60
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_animation"))
      end

      it "gets unique audio file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          audio: Tourmaline::Audio.new(
            file_id: "audio_item_one",
            file_unique_id: "unique_audio",
            duration: 60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_audio"))
      end

      it "gets unique document file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          document: Tourmaline::Document.new(
            file_id: "document_item_one",
            file_unique_id: "unique_document",
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_document"))
      end

      it "gets unique video file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          video: Tourmaline::Video.new(
            file_id: "video_item_one",
            file_unique_id: "unique_video",
            width: 1080,
            height: 1080,
            duration: 60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_video"))
      end

      it "gets unique video note file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          video_note: Tourmaline::VideoNote.new(
            file_id: "video_note_item_one",
            file_unique_id: "unique_video_note",
            length: 1080,
            duration: 60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_video_note"))
      end

      it "gets unique voice file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          voice: Tourmaline::Voice.new(
            file_id: "voice_item_one",
            file_unique_id: "unique_voice",
            duration: 60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_voice"))
      end

      it "gets unique photo file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ],
        )

        r9k.get_media_file_id(message).should(eq("unique_photo"))
      end

      it "gets unique sticker file id" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          sticker: Tourmaline::Sticker.new(
            file_id: "sticker_item_one",
            file_unique_id: "unique_sticker",
            type: "regular",
            width: 1080,
            height: 1080,
            is_animated: false,
            is_video: false,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_sticker"))
      end

      it "returns nil if message did not match any message type" do
        r9k = MockRobot9000.new

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        message = Tourmaline::Message.new(
          message_id: 11,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "Example"
        )

        r9k.get_media_file_id(message).should(be_nil)
      end
    end

    describe "#checks" do
      it "returns true if message is unique" do
        services = create_services()

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.checks(user, message, services).should(be_true)
      end

      it "returns true if message is preformatted" do
        services = create_services()

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.checks(user, message, services).should(be_true)

        message2 = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        message2.preformatted = true

        Robot9000.checks(user, message2, services).should(be_true)
      end

      it "returns false if message fails r9k text check" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.checks(user, message, r9k_services).should(be_true)

        Robot9000.checks(user, message, r9k_services).should(be_false)
      end

      it "returns false if message fails r9k media check" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.checks(user, message, r9k_services).should(be_true)

        Robot9000.checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#forward_checks" do
      # TODO: Remove this test when removing Robot9000's class methods
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.forward_checks(user, message, services).should(be_true)
      end

      it "returns true if r9k service does not check forwards" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.forward_checks(user, message, r9k_services).should(be_true)
      end

      it "returns true if forwarded message is unique" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
            check_forwards: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.forward_checks(user, message, r9k_services).should(be_true)
      end

      it "returns false if message fails r9k text check" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_text: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.forward_checks(user, message, r9k_services).should(be_true)

        Robot9000.forward_checks(user, message, r9k_services).should(be_false)
      end

      it "returns false if message fails r9k media check" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_media: true
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.forward_checks(user, message, r9k_services).should(be_true)

        Robot9000.forward_checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#text_check" do
      # TODO: Remove this test when removing Robot9000's class methods
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, services).should(be_true)
      end

      it "returns true if Robot9000 does not check text" do
        r9k_services = create_services(
          r9k: MockRobot9000.new
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services).should(be_true)
      end

      it "returns false if text is unoriginal" do
        r9k_services = create_services(

          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services).should(be_true)

        Robot9000.text_check(user, message, r9k_services).should(be_false)
      end

      it "cooldowns user if text is unoriginal" do
        r9k_services = create_services(

          r9k: MockRobot9000.new(
            check_text: true,
            cooldown: 10,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services)

        user.cooldown_until.should(be_nil)

        Robot9000.text_check(user, message, r9k_services)

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if text is unoriginal" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            warn_user: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, warnings: 0)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        Robot9000.text_check(user, message, r9k_services)

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "stores line of text and returns true if text is original" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services).should(be_true)

        unless r9k = r9k_services.robot9000
          fail("Services should contain a Robot9000 service")
        end

        r9k.as(MockRobot9000).lines.should(contain("example text"))
      end
    end

    describe "#media_check" do
      # TODO: Remove this test when removing Robot9000's class methods
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, services).should(be_true)
      end

      it "returns true if Robot900 does not check media" do
        r9k_services = create_services(
          r9k: MockRobot9000.new
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services).should(be_true)
      end

      it "returns true if message did not have a file ID" do
        r9k_services = create_services(
          r9k: MockRobot9000.new
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "Example Text",
        )

        Robot9000.media_check(user, message, r9k_services).should(be_true)
      end

      it "returns false if media is unoriginal" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services).should(be_true)

        Robot9000.media_check(user, message, r9k_services).should(be_false)
      end

      it "cooldowns user if media is unoriginal" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
            cooldown: 10,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services)

        user.cooldown_until.should(be_nil)

        Robot9000.media_check(user, message, r9k_services)

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if media is unoriginal" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
            warn_user: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, warnings: 0)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        Robot9000.media_check(user, message, r9k_services)

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "stores file id and returns true if media is original" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              file_id: "photo_item_one",
              file_unique_id: "unique_photo",
              width: 1080,
              height: 1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services).should(be_true)

        unless r9k = r9k_services.robot9000
          fail("Services should contain a Robot9000 service")
        end

        r9k.as(MockRobot9000).files.should(contain("unique_photo"))
      end
    end
  end
end
