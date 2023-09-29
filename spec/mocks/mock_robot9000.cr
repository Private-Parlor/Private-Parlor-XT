require "../spec_helper.cr"

module PrivateParlorXT
  class MockRobot9000 < Robot9000
    getter lines : Set(String) = Set(String).new
    getter files : Set(String) = Set(String).new

    def initialize(
      @valid_codepoints : Array(Range(Int32, Int32)) = [(0x0000..0x007F)],
      @check_text : Bool? = nil,
      @check_media : Bool? = nil,
      @check_forwards : Bool? = nil,
      @warn_user : Bool? = nil,
      @cooldown : Int32 = 0
    )
    end

    def unoriginal_text?(text : String) : Bool?
      lines.includes?(text)
    end

    def add_line(text : String) : Nil
      lines.add(text)
    end

    def unoriginal_media?(id : String) : Bool?
      files.includes?(id)
    end

    def add_file_id(id : String) : Nil
      files.add(id)
    end
  end
end
