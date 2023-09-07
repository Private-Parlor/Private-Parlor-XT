require "./private-parlor-xt/**"
require "tourmaline"

module PrivateParlorXT
  VERSION = "0.1.0"

  unless (var = ENV["TEST"]?) && var.downcase == "true"
    client = Tourmaline::Client.new(bot_token: ENV["BOT_TOKEN"])

    initialize_handlers(client)

    client.poll
  end
  



  def self.initialize_handlers(client : Tourmaline::Client) : Nil
    events = [] of Tourmaline::EventHandler

    events = events.concat(generate_command_handlers)
    #TODO: Add Inline Queries
    #TODO: Add Hears Handlers

    events.each do |handler|
      client.register(handler)
    end

    generate_update_handlers(client)
  end

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler

    {% for command in CommandHandler.all_subclasses.select { |sub_class| 
      (responds_to = sub_class.annotation(RespondsTo))} %}

    {{command_responds_to = command.annotation(RespondsTo)[:command]}}

    command = {{command}}.new

    arr << Tourmaline::CommandHandler.new({{command_responds_to}}) do |ctx|
      command.do(ctx)
    end

  {% end %}

    arr
  end

  def self.generate_update_handlers(client : Tourmaline::Client) : Nil
    {% for update in UpdateHandler.all_subclasses.select { |sub_class| 
      (on = sub_class.annotation(On))}%}

    {{update_on = update.annotation(On)[:update]}}

    handler = {{update}}.new

    client.on({{update_on}}) do |ctx|
      handler.do(ctx)
    end

    {% end %}
  end
end
