require "../spec_helper.cr"

module PrivateParlorXT
  describe Format do
    describe "#substitute_message" do
      it "globally substitutes placeholders" do
        placeholder_text = "User {id} sent a message [{message_id}] (origin: {message_id})"

        parameters = {
          "id"         => 9000.to_s,
          "message_id" => 20.to_s,
        }

        expected = "User 9000 sent a message [20] (origin: 20)"

        Format.substitute_message(placeholder_text, parameters).should(eq(expected))
      end

      it "does not raise KeyError when placeholder is not found in parameters" do
        placeholder_text = "User {id} sent a {type} message [{message_id}] (origin: {message_id})"

        parameters = {
          "id"         => 9000.to_s,
          "message_id" => 20.to_s,
        }

        expected = "User 9000 sent a  message [20] (origin: 20)"

        Format.substitute_message(placeholder_text, parameters).should(eq(expected))
      end
    end

    describe "#remove_entities" do
      it "should remove only the given entity types" do
        strip_types = ["bold", "text_link"]

        entities = [
          Tourmaline::MessageEntity.new(
            "bold",
            3,
            4,
          ),
          Tourmaline::MessageEntity.new(
            "bold",
            10,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "text_link",
            10,
            7,
            "https://crystal-lang.org",
          ),
          Tourmaline::MessageEntity.new(
            "italic",
            20,
            4,
          ),
        ]

        updated_entities = Format.remove_entities(entities, strip_types)

        updated_entities.should_not(eq(entities))
        updated_entities.size.should(eq(1))
        updated_entities[0].should(eq(entities[3]))
      end
    end

    describe "#generate_tripcode" do
      it "generates 8chan secure tripcodes" do
        salt = "ASecureSalt"
        Format.generate_tripcode("name#password", salt).should(eq({"name", "!tOi2ytmic0"}))
        Format.generate_tripcode("example#1", salt).should(eq({"example", "!8KD/BUYBBu"}))
        Format.generate_tripcode("example#pass", salt).should(eq({"example", "!LhfgvU61/K"}))
      end

      it "generates 2channel tripcodes" do
        Format.generate_tripcode("name#password", "").should(eq({"name", "!ozOtJW9BFA"}))
        Format.generate_tripcode("example#1", "").should(eq({"example", "!tsGpSwX8mo"}))
        Format.generate_tripcode("example#pass", "").should(eq({"example", "!XksB4AwhxU"}))

        Format.generate_tripcode(
          "example#AnExcessivelyLongTripcodePassword", ""
        ).should(eq({"example", "!v8ZIGlF0Uc"}))
        Format.generate_tripcode(
          "example#AnExcess", ""
        ).should(eq({"example", "!v8ZIGlF0Uc"}))
      end
    end

    describe "#replace_links" do
      it "appends text link to string" do
        text = "Text link example"

        entities = [
          Tourmaline::MessageEntity.new(
            "text_link",
            10,
            7,
            "https://crystal-lang.org",
          ),
        ]

        expected = "Text link example\n(https://crystal-lang.org)"

        Format.replace_links(text, entities).should(eq(expected))
      end
    end

    describe "#format_network_links" do
      network = {
        "foo"  => "foochatbot",
        "fizz" => "fizzchatbot",
      }

      it "only formats chats in linked network" do
        text = "Backlinks: >>>/foo/ >>>/bar/ >>>/fizz/"

        entities = Format.format_network_links(text, [] of Tourmaline::MessageEntity, network)

        entities.size.should(eq(2))

        unless entities[0].url
          fail("Backlink entities should contain a url")
        end

        unless entities[1].url
          fail("Backlink entities should contain a url")
        end

        entities[0].type.should(eq("text_link"))
        entities[0].length.should(eq(8))
        entities[0].offset.should(eq(11))
        entities[0].url.should(eq("tg://resolve?domain=foochatbot"))

        entities[1].type.should(eq("text_link"))
        entities[1].length.should(eq(9))
        entities[1].offset.should(eq(29))
        entities[1].url.should(eq("tg://resolve?domain=fizzchatbot"))
      end
    end

    describe "#allow_text?" do
      it "returns true if there is no text" do
        Format.allow_text?("").should(be_true)
      end

      it "returns true if text is allowed" do
        Format.allow_text?("example text").should(be_true)
      end

      it "returns false if text is not allowed" do
        Format.allow_text?("𝐀𝐁𝐂").should(be_false)
      end
    end

    describe "#get_arg" do
      it "returns the string that follows the first whitespace in text" do
        command = "/test something"

        expected = "something"

        Format.get_arg(command).should(eq(expected))
      end

      it "returns nil if there is no given text" do
        Format.get_arg(nil).should(be_nil)
      end
    end

    describe "#get_args" do
      it "returns an array of strings that follow the first whitespace in text" do
        command = "/test do something special"

        count_one = ["do something special"]
        count_two = ["do", "something special"]
        count_three = ["do", "something", "special"]

        Format.get_args(command, 1).should(eq(count_one))
        Format.get_args(command, 2).should(eq(count_two))
        Format.get_args(command, 3).should(eq(count_three))
        Format.get_args(command, 4).should(eq(count_three))
      end

      it "returns nil if there is no given text" do
        Format.get_args(nil, 1).should(be_nil)
      end
    end

    describe "#regular_forward?" do
      it "returns true if message is a regular forward" do
        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            "bold",
            0,
            19,
          ),
        ]

        Format.regular_forward?(text, entities).should(be_true)
      end

      it "returns false if message is not a regular forward" do
        text = "Forwarded from User"

        entities = [
          Tourmaline::MessageEntity.new(
            "italic",
            0,
            19,
          ),
        ]

        Format.regular_forward?(text, entities).should(be_false)
      end

      it "returns nil if given no entities" do
        text = "Forwarded from User"

        Format.regular_forward?(text, [] of Tourmaline::MessageEntity).should(be_nil)
      end

      it "returns nil if given no text" do
        Format.regular_forward?(nil, [] of Tourmaline::MessageEntity).should(be_nil)
      end
    end

    describe "#get_forward_header" do
      it "returns header and entities for forwards from users with public forwards" do
        message = create_message(
          100_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          forward_from: Tourmaline::User.new(
            9000,
            is_bot: false,
            first_name: "example",
            last_name: nil,
          )
        )

        header, entities = Format.get_forward_header(message, [] of Tourmaline::MessageEntity)

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
        message = create_message(
          100_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          forward_from: Tourmaline::User.new(
            9000,
            is_bot: true,
            first_name: "ExampleBot",
            last_name: nil,
            username: "example_bot"
          )
        )

        header, entities = Format.get_forward_header(message, [] of Tourmaline::MessageEntity)

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
        message = create_message(
          100_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          forward_from_message_id: 200_i64,
          forward_from_chat: Tourmaline::Chat.new(
            9000,
            type: "channel",
            title: "Example Channel",
            username: "ExamplesChannel"
          )
        )

        header, entities = Format.get_forward_header(message, [] of Tourmaline::MessageEntity)

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
        message = create_message(
          100_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          forward_from_message_id: 200_i64,
          forward_from_chat: Tourmaline::Chat.new(
            -1009000,
            type: "private",
            title: "Private Example Channel",
          )
        )

        header, entities = Format.get_forward_header(message, [] of Tourmaline::MessageEntity)

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
        message = create_message(
          100_i64,
          Tourmaline::User.new(80300, false, "beispiel"),
          forward_sender_name: "Private User"
        )

        header, entities = Format.get_forward_header(message, [] of Tourmaline::MessageEntity)

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

    describe "#format_user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.format_user_forward(
          "Dodo 🦤🏝🍽",
          9000,
          [
            Tourmaline::MessageEntity.new(
              "underline",
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

    describe "#format_private_user_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.format_private_user_forward(
          "Private 🔒🦤 Dodo",
          [
            Tourmaline::MessageEntity.new(
              "underline",
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

    describe "#format_username_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.format_username_forward(
          "🤖 Dodo Bot 🦤",
          "dodobot",
          [
            Tourmaline::MessageEntity.new(
              "underline",
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

    describe "format_private_channel_forward" do
      it "handles UTF-16 code units in given name and updates entities" do
        header, entities = Format.format_private_channel_forward(
          "🦤 Private 🔒 Dodo 📣",
          9000,
          [
            Tourmaline::MessageEntity.new(
              "underline",
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

    describe "#offset_entities" do
      it "adds offset to each entity's offset field" do
        entities = [
          Tourmaline::MessageEntity.new(
            "bold",
            3,
            4,
          ),
          Tourmaline::MessageEntity.new(
            "bold",
            10,
            7,
          ),
          Tourmaline::MessageEntity.new(
            "text_link",
            10,
            7,
            "https://crystal-lang.org",
          ),
          Tourmaline::MessageEntity.new(
            "italic",
            20,
            4,
          ),
        ]

        updated_entities = Format.offset_entities(entities, 10)

        updated_entities[0].offset.should(eq(13))
        updated_entities[1].offset.should(eq(20))
        updated_entities[2].offset.should(eq(20))
        updated_entities[3].offset.should(eq(30))
      end
    end

    describe "#format_smiley" do
      it "returns smiley face based on number of given warnings" do
        smileys = [":)", ":O", ":/", ">:("]

        Format.format_smiley(0, smileys).should(eq(":)"))
        Format.format_smiley(1, smileys).should(eq(":O"))
        Format.format_smiley(2, smileys).should(eq(":O"))
        Format.format_smiley(3, smileys).should(eq(":/"))
        Format.format_smiley(4, smileys).should(eq(":/"))
        Format.format_smiley(5, smileys).should(eq(":/"))
        Format.format_smiley(6, smileys).should(eq(">:("))
        Format.format_smiley(7, smileys).should(eq(">:("))
      end
    end

    describe "#format_karma_loading_bar" do
      client = MockClient.new

      services = create_services(client: client)

      it "returns full bar when percentage is 100%" do
        expected = services.locale.loading_bar[2] * 10

        bar = Format.format_karma_loading_bar(100.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns empty bar when percentage is 0%" do
        expected = services.locale.loading_bar[0] * 10

        bar = Format.format_karma_loading_bar(0.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns bar with a half filled pip when percentage is 55%" do
        expected = services.locale.loading_bar[2] * 5
        expected = expected + services.locale.loading_bar[1]
        expected = expected + services.locale.loading_bar[0] * 4

        bar = Format.format_karma_loading_bar(55.0_f32, services.locale)

        bar.should(eq(expected))
      end

      it "returns partially filled bar when percentage has a remainder less than 5" do
        expected = services.locale.loading_bar[2] * 3
        expected = expected + services.locale.loading_bar[0] * 7

        bar = Format.format_karma_loading_bar(33.3_f32, services.locale)

        bar.should(eq(expected))
      end
    end
  end
end
