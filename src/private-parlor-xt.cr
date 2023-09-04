require "./private-parlor-xt/**"
require "tourmaline"

module PrivateParlorXT
  VERSION = "0.1.0"

  unless ENV["TEST"].downcase == "true"
    client = Tourmaline::Client.new(bot_token: ENV["BOT_TOKEN"])

    initialize_handlers(client)

    client.poll
  end
  



  def self.initialize_handlers(client : Tourmaline::Client) : Nil
    arr = [] of Tourmaline::EventHandler

    arr = arr.concat(generate_command_handlers)

    arr.each do |handler|
      client.register(handler)
    end
  end

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler

    {% for command in CommandHandler.all_subclasses.select { |sub_class| 
      (responds_to = sub_class.annotation(RespondsTo)) &&
      responds_to[:command].is_a?(ArrayLiteral) &&
      responds_to[:command].all? { |type| type.is_a?(StringLiteral)}} %}

    {{command_responds_to = command.annotation(RespondsTo)[:command]}}

    command = {{command}}.new

    arr << Tourmaline::CommandHandler.new({{command_responds_to}}) do |ctx|
      command.do(ctx)
    end

  {% end %}

    arr
  end
end
