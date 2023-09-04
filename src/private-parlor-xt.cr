require "./private-parlor-xt/**"
require "tourmaline"

module PrivateParlorXT
  VERSION = "0.1.0"


  client = Tourmaline::Client.new(bot_token: ENV["BOT_TOKEN"])

  ##
  ## Initialize Command Handlers
  ##
  {% for command in CommandHandler.all_subclasses.select { |sub_class| 
      (responds_to = sub_class.annotation(RespondsTo)) &&
      responds_to[:command].is_a?(ArrayLiteral) &&
      responds_to[:command].all? { |type| type.is_a?(StringLiteral)}} %}

    command = {{command}}.new

    handler = Tourmaline::CommandHandler.new({{responds_to[:command]}}) do |ctx|
      command.do(ctx)
    end

    client.register(handler)
  {% end %}

  client.poll
end
