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
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services).should(be_true)
      end

      it "returns true if message is preformatted" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services).should(be_true)

        message2 = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        message2.preformatted = true

        r9k.unique_message?(user, message2, services).should(be_true)
      end

      it "returns true if r9k service does not check forwards and message is a forward" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.unique_message?(user, message, services).should(be_true)
      end

      it "stores line of text and returns true if text is original" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.as(MockRobot9000).lines.should(contain("example text"))
      end

      it "stores file id and returns true if media is original" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.as(MockRobot9000).files.should(contain("unique_photo"))
      end

      it "stores text and file id, and returns true if media is original" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.as(MockRobot9000).lines.should(contain("example text"))
        r9k.as(MockRobot9000).files.should(contain("unique_photo"))
      end
      
      it "returns true if message did not have a file ID" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          text: "Example Text",
        )

        r9k.unique_message?(user, message, services).should(be_true)
      end

      it "returns true if forwarded message is unique" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            check_media: true,
            check_forwards: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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
          ],
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        r9k.unique_message?(user, message, services).should(be_true)
      end

      it "returns false if fowarded message fails r9k text check" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_text: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.unique_message?(user, message, services).should(be_false)
      end

      it "returns false if fowarded message fails r9k media check" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_forwards: true,
            check_media: true
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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
          ],
          forward_origin: Tourmaline::MessageOriginUser.new(
            "user",
            Time.utc,
            Tourmaline::User.new(123456, false, "other user")
          ),
        )

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.unique_message?(user, message, services).should(be_false)
      end

      it "returns false if message fails r9k text check" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.unique_message?(user, message, services).should(be_false)
      end

      it "returns false if message fails r9k media check" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        r9k.unique_message?(user, message, services).should(be_true)

        r9k.unique_message?(user, message, services).should(be_false)
      end
    end

    describe "#unique_text" do
      it "returns text if text is original" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            warn_user: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, warnings: 0)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        result = r9k.unique_text(user, message, services, "example text")

        result.should(eq("example text"))
      end

      it "returns nil if text is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services)

        r9k.unique_text(user, message, services, "example text").should(be_nil)
      end

      it "cooldowns user if text is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            cooldown: 10,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services)

        user.cooldown_until.should(be_nil)

        r9k.unique_text(user, message, services, "example text")

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if text is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            warn_user: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, warnings: 0)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        r9k.unique_text(user, message, services, "example text")

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "increments unoriginal text message count if statistics are enabled" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          database: database,
          r9k: SQLiteRobot9000.new(
            connection,
            check_text: true,
          ),
          statistics: SQLiteStatistics.new(connection)
        )

        generate_users(services.database)

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        unless stats = services.stats
          fail("Services should have a Statistics object")
        end

        tourmaline_user = Tourmaline::User.new(12345678, true, "Spec", username: "bot_bot")

        user = MockUser.new(12345678, warnings: 0)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unique_message?(user, message, services)

        statistics = stats.get_robot9000_counts()

        statistics[Statistics::Robot9000Counts::TotalUnoriginal].should(eq(0))
        statistics[Statistics::Robot9000Counts::UnoriginalText].should(eq(0))

        r9k.unique_text(user, message, services, "example text")

        statistics = stats.get_robot9000_counts()

        statistics[Statistics::Robot9000Counts::TotalUnoriginal].should(eq(1))
        statistics[Statistics::Robot9000Counts::UnoriginalText].should(eq(1))
      end
    end

    describe "#unique_media" do
      it "returns file_id if media is original" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        result = r9k.unique_media(user, message, services, "unique_photo")

        result.should(eq("unique_photo"))
      end

      it "returns nil if media is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        result = r9k.unique_message?(user, message, services)

        result.should(be_true)

        result = r9k.unique_media(user, message, services, "unique_photo")

        result.should(be_nil)
      end

      it "cooldowns user if media is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
            cooldown: 10,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        r9k.unique_message?(user, message, services)

        user.cooldown_until.should(be_nil)

        r9k.unique_media(user, message, services, "unique_photo")

        user.cooldown_until.should_not(be_nil)
      end

      it "warns user if media is unoriginal" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_media: true,
            warn_user: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

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

        r9k.unique_message?(user, message, services)

        user.warnings.should(eq(0))
        user.cooldown_until.should(be_nil)

        r9k.unique_media(user, message, services, "unique_photo")

        user.warnings.should(eq(1))
        user.cooldown_until.should_not(be_nil)
      end

      it "increments unoriginal media message count if statistics are enabled" do
        connection = DB.open("sqlite3://%3Amemory%3A")
        database = SQLiteDatabase.new(connection)

        services = create_services(
          database: database,
          r9k: SQLiteRobot9000.new(
            connection,
            check_media: true,
          ),
          statistics: SQLiteStatistics.new(connection)
        )

        generate_users(services.database)

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        unless stats = services.stats
          fail("Services should have a Statistics object")
        end

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

        r9k.unique_message?(user, message, services)

        statistics = stats.get_robot9000_counts()

        statistics[Statistics::Robot9000Counts::TotalUnoriginal].should(eq(0))
        statistics[Statistics::Robot9000Counts::UnoriginalMedia].should(eq(0))

        r9k.unique_media(user, message, services, "unique_photo")

        statistics = stats.get_robot9000_counts()

        statistics[Statistics::Robot9000Counts::TotalUnoriginal].should(eq(1))
        statistics[Statistics::Robot9000Counts::UnoriginalMedia].should(eq(1))
      end
    end

    describe "#unoriginal_message" do
      it "cooldowns user and queues 'robot9000 cooldown' response if cooldown is greater than 0" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            cooldown: 10
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, warnings: 0, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unoriginal_message(user, message, services)

        user.cooldown_until.should_not(be_nil)
        user.warnings.should_not(eq(1))

        expected = Format.substitute_reply(services.replies.r9k_cooldown, {
          "duration" => Format.format_time_span(10.seconds, services.locale),
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "warns and cooldowns user using standard cooldowns and queues 'robot9000 cooldown' response if warnings are enabled" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
            warn_user: true
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, warnings: 1, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unoriginal_message(user, message, services)

        unless cooldown = user.cooldown_until
          fail("User should have received a cooldown")
        end

        (cooldown - Time.utc).should(be > 1.minute)
        user.warnings.should(eq(2))

        expected = Format.substitute_reply(services.replies.r9k_cooldown, {
          "duration" => Format.format_time_span(5.minutes, services.locale),
        })

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(expected))
      end

      it "queues 'unoriginal message' response if not giving the user a cooldown" do
        services = create_services(
          r9k: MockRobot9000.new(
            check_text: true,
          )
        )

        unless r9k = services.robot9000
          fail("Services should have a ROBOT9000 object")
        end

        tourmaline_user = Tourmaline::User.new(80300, false, "beispiel")

        user = MockUser.new(80300, warnings: 0, cooldown_until: nil)

        message = Tourmaline::Message.new(
          message_id: 6,
          date: Time.utc,
          chat: Tourmaline::Chat.new(tourmaline_user.id, "private"),
          caption: "Example Text",
        )

        r9k.unoriginal_message(user, message, services)

        user.cooldown_until.should(be_nil)
        user.warnings.should_not(eq(1))

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(1))
        messages[0].data.should(eq(services.replies.unoriginal_message))
      end
    end
  end
end
