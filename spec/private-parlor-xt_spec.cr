require "./spec_helper"

describe PrivateParlorXT do

  it "generates command handlers" do
    arr = PrivateParlorXT.generate_command_handlers()

    contains_mock = false
    arr.each do |command|
      if command.commands.includes?("mock_test")
        contains_mock = true
      end
    end

    contains_mock.should(eq(true))
  end
end
