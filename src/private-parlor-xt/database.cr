module PrivateParlorXT
  abstract class Database

    def initialize()
    end

    def self.instance(*any)
      @@instance ||= new(any)
    end

  end
end