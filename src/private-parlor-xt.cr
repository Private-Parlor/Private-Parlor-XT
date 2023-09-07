require "./private-parlor-xt/**"
require "tourmaline"

module PrivateParlorXT
  VERSION = "0.1.0"

  client = Tourmaline::Client.new(bot_token: ENV["BOT_TOKEN"])

  initialize_handlers(client)

  client.poll
  
end
