require "../spec_helper.cr"

module PrivateParlorXT
  # A subtype of `Client` without using Telegram API on init
  class MockClient < Client
    def initialize(@bot_token : String = "",
                   @endpoint = DEFAULT_API_URL,
                   @default_parse_mode : Tourmaline::ParseMode = :markdown,
                   pool_capacity = 200,
                   initial_pool_size = 20,
                   pool_timeout = 0.1,
                   proxy = nil,
                   proxy_uri = nil,
                   proxy_host = nil,
                   proxy_port = nil,
                   proxy_user = nil,
                   proxy_pass = nil)
      if !proxy
        if proxy_uri
          proxy_uri = proxy_uri.is_a?(URI) ? proxy_uri : URI.parse(proxy_uri.starts_with?("http") ? proxy_uri : "http://#{proxy_uri}")
          proxy_host = proxy_uri.host
          proxy_port = proxy_uri.port
          proxy_user = proxy_uri.user if proxy_uri.user
          proxy_pass = proxy_uri.password if proxy_uri.password
        end

        if proxy_host && proxy_port
          proxy = HTTP::Proxy::Client.new(proxy_host, proxy_port, username: proxy_user, password: proxy_pass)
        end
      end

      @pool = DB::Pool(HTTP::Client).new(max_pool_size: pool_capacity, initial_pool_size: initial_pool_size, checkout_timeout: pool_timeout) do
        client = HTTP::Client.new(URI.parse(endpoint))
        client.proxy = proxy.dup if proxy
        client
      end
    end
  end
end
