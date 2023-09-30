require "../spec_helper.cr"

module PrivateParlorXT
  describe SQLiteRobot9000 do
    describe "#unoriginal_text?" do
      it "returns true if text is unoriginal" do
        r9k = SQLiteRobot9000.new(
          DB.open("sqlite3://%3Amemory%3A"),
          check_text: true,
        )

        r9k.unoriginal_text?("example").should(be_falsey)

        r9k.add_line("example")

        r9k.unoriginal_text?("example").should(be_true)
      end

      it "returns false if text is original" do
        r9k = SQLiteRobot9000.new(
          DB.open("sqlite3://%3Amemory%3A"),
          check_text: true,
        )

        r9k.unoriginal_text?("example").should(be_falsey)
      end
    end

    describe "#unoriginal_media?" do
      it "returns true if media is unoriginal" do
        r9k = SQLiteRobot9000.new(
          DB.open("sqlite3://%3Amemory%3A"),
          check_media: true,
        )

        r9k.unoriginal_media?("unique_photo").should(be_falsey)

        r9k.add_file_id("unique_photo")

        r9k.unoriginal_media?("unique_photo").should(be_true)
      end

      it "returns false if text is original" do
        r9k = SQLiteRobot9000.new(
          DB.open("sqlite3://%3Amemory%3A"),
          check_media: true,
        )

        r9k.unoriginal_media?("unique_photo").should(be_falsey)
      end
    end
  end
end
