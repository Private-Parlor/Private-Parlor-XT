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
            "url",
            28,
            22,
          ),
          Tourmaline::MessageEntity.new(
            "url",
            51,
            15,
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
                   "and _NOT MUCH_ else."

        url_entity = Tourmaline::MessageEntity.new(
          "url",
          29,
          15,
        )

        text_two = "A text that references.\n" \
                   "a user @username and a /pin command."

        text_three = "A tttteeeeexxxxttttt _trying_ *22222* bbbe >>>/foo/ original,"

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
        )

        r9k.get_media_file_id(message).should(eq("unique_animation"))
      end

      it "gets unique audio file id" do
        r9k = MockRobot9000.new

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          audio: Tourmaline::Audio.new(
            "audio_item_one",
            "unique_audio",
            60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_audio"))
      end

      it "gets unique document file id" do
        r9k = MockRobot9000.new

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          document: Tourmaline::Document.new(
            "document_item_one",
            "unique_document",
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_document"))
      end

      it "gets unique video file id" do
        r9k = MockRobot9000.new

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
        )

        r9k.get_media_file_id(message).should(eq("unique_video"))
      end

      it "gets unique video note file id" do
        r9k = MockRobot9000.new

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          video_note: Tourmaline::VideoNote.new(
            "video_note_item_one",
            "unique_video_note",
            1080,
            60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_video_note"))
      end

      it "gets unique voice file id" do
        r9k = MockRobot9000.new

        message = create_message(
          11,
          Tourmaline::User.new(80300, false, "beispiel"),
          voice: Tourmaline::Voice.new(
            "voice_item_one",
            "unique_voice",
            60,
          ),
        )

        r9k.get_media_file_id(message).should(eq("unique_voice"))
      end

      it "gets unique voice file id" do
        r9k = MockRobot9000.new

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
        )

        r9k.get_media_file_id(message).should(eq("unique_photo"))
      end

      it "gets unique sticker file id" do
        r9k = MockRobot9000.new

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
        )

        r9k.get_media_file_id(message).should(eq("unique_sticker"))
      end
    end

    describe "#checks" do
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        Robot9000.checks(user, message, services).should(be_true)
      end

      it "returns false if message fails r9k text check" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        Robot9000.checks(user, message, r9k_services).should(be_true)

        Robot9000.checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#forward_checks" do
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        Robot9000.forward_checks(user, message, r9k_services).should(be_true)

        Robot9000.forward_checks(user, message, r9k_services).should(be_false)
      end
    end

    describe "#text_check" do
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, services).should(be_true)
      end

      it "returns true if Robot900 does not check text" do
        r9k_services = create_services(
          r9k: MockRobot9000.new
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000, cooldown_until: nil)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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

        user = MockUser.new(9000, warnings: 0)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
        )

        Robot9000.text_check(user, message, r9k_services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        Robot9000.text_check(user, message, r9k_services)

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "stores line of text if text is original" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
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
      it "returns true if there is no Robot9000 service available" do
        services = create_services()

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, services).should(be_true)
      end

      it "returns true if Robot900 does not check media" do
        r9k_services = create_services(
          r9k: MockRobot9000.new
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
            ),
          ]
        )

        Robot9000.media_check(user, message, r9k_services).should(be_true)
      end

      it "returns false if media is unoriginal" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
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

        user = MockUser.new(9000, cooldown_until: nil)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
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

        user = MockUser.new(9000, warnings: 0)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
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

      it "stores file id if media is original" do
        r9k_services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        user = MockUser.new(9000)

        message = create_message(
          6_i64,
          Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot"),
          caption: "Example Text",
          photo: [
            Tourmaline::PhotoSize.new(
              "photo_item_one",
              "unique_photo",
              1080,
              1080,
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
