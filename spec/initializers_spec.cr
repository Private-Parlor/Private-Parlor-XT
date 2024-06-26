require "./spec_helper"

module PrivateParlorXT
  @[RespondsTo(command: "hardcode")]
  class HardCodedCommand < CommandHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  @[On(update: :SupergroupChatCreated)]
  class HardCodedUpdate < UpdateHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  @[Hears(pattern: /^test/, command: true)]
  class HardCodedHearsHandler < HearsHandler
    def do(message : Tourmaline::Message, services : Services) : Nil
    end
  end

  describe PrivateParlorXT do
    describe "#generate_command_handlers" do
      it "generates command handlers" do
        config = MockConfig.new
        client = MockClient.new

        services = create_services()

        arr = PrivateParlorXT.generate_command_handlers(config, client, services)

        contains_mock = false
        arr.each do |command|
          if command.commands.includes?("mock_test")
            contains_mock = true
          end
        end

        contains_mock.should(eq(true))
      end

      it "generates command handlers for commands without a config toggle" do
        config = MockConfig.new
        client = MockClient.new

        services = create_services()

        arr = PrivateParlorXT.generate_command_handlers(config, client, services)

        contains_mock = false
        arr.each do |command|
          if command.commands.includes?("hardcode")
            contains_mock = true
          end
        end

        contains_mock.should(eq(true))
      end
    end

    describe "#generate_update_handlers" do
      it "generates update handlers" do
        config = MockConfig.new
        client = MockClient.new

        services = create_services()

        PrivateParlorXT.generate_update_handlers(config, client, services)

        registered_actions = client.dispatcher.event_handlers.keys

        registered_actions.should(contain(Tourmaline::UpdateAction::NewChatMembers))
      end

      it "generates update handlers for updates without a config toggle" do
        config = MockConfig.new
        client = MockClient.new

        services = create_services()

        PrivateParlorXT.generate_update_handlers(config, client, services)

        registered_actions = client.dispatcher.event_handlers.keys

        registered_actions.should(contain(Tourmaline::UpdateAction::SupergroupChatCreated))
      end
    end

    describe "#generate_hears_handlers" do
      it "generates hears handlers" do
        config = MockConfig.new

        services = create_services()

        arr = PrivateParlorXT.generate_hears_handlers(config, services)

        contains_mock = false
        arr.each do |handler|
          if handler.pattern == /mockpattern/
            contains_mock = true
          end
        end

        contains_mock.should(eq(true))
      end

      it "generates hears handlers for handlers without a config toggle" do
        config = MockConfig.new

        services = create_services()

        arr = PrivateParlorXT.generate_hears_handlers(config, services)

        contains_mock = false
        arr.each do |handler|
          if handler.pattern == /^test/
            contains_mock = true
          end
        end

        contains_mock.should(eq(true))
      end
    end

    it "kicks inative users" do
      fresh_services = create_services()

      generate_users(fresh_services.database)

      kick_inactive_users(10.minutes, fresh_services)

      unless user_one = fresh_services.database.get_user(20000)
        fail("User 20000 should exist in the database")
      end

      unless user_two = fresh_services.database.get_user(60200)
        fail("User 60200 should exist in the database")
      end

      unless user_three = fresh_services.database.get_user(80300)
        fail("User 80300 should exist in the database")
      end

      unless user_four = fresh_services.database.get_user(50000)
        fail("User 50000 should exist in the database")
      end

      user_one.left.should_not(be_nil)
      user_two.left.should_not(be_nil)
      user_three.left.should_not(be_nil)
      user_four.left.should_not(be_nil)
    end
  end
end
