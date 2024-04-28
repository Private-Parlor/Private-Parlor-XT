require "../spec_helper.cr"

module PrivateParlorXT
  @[Hears(text: "mockpattern", config: "enable_mockpattern", command: true)]
  class MockHearsHandler < HearsHandler
    def do(message : Tourmaline::Message, services : Services)
    end
  end
end