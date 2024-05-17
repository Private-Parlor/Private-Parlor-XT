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

    describe "#add_line" do
      it "adds line of text to database" do
        connection = DB.open("sqlite3://%3Amemory%3A")

        r9k = SQLiteRobot9000.new(
          connection: connection,
          check_text: true,
        )

        line = "unique line of text"

        r9k.add_line(line)

        result = connection.query_one?("
          SELECT line
          FROM text
          WHERE line = ?
        ", args: [line], as: String)

        result.should(eq(line))
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

    describe "#add_file_id" do
      it "adds file id to database" do
        connection = DB.open("sqlite3://%3Amemory%3A")

        r9k = SQLiteRobot9000.new(
          connection: connection,
          check_media: true,
        )

        file_id = "unique_file_id"

        r9k.add_file_id(file_id)

        result = connection.query_one?("
          SELECT id
          FROM file_id
          WHERE id = ?
        ", args: [file_id], as: String)

        result.should(eq(file_id))
      end
    end

    describe "#ensure_schema" do
      it "creates text and file_id tables" do
        connection = DB.open("sqlite3://%3Amemory%3A")

        r9k = SQLiteRobot9000.new(
          connection: connection,
        )

        r9k.ensure_schema

        result_text = connection.query_one?("
          SELECT EXISTS (
            SELECT name FROM sqlite_schema WHERE type='table' AND name='text'
          )", 
          as: Int32
        )

        result_file_id = connection.query_one?("
          SELECT EXISTS (
            SELECT name FROM sqlite_schema WHERE type='table' AND name='file_id'
          )", 
          as: Int32
        )

        result_text.should(eq(1))
        result_file_id.should(eq(1))
      end
    end
  end
end
