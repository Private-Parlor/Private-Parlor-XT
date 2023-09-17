require "./config/handler_config.cr"
require "./locale/locale.cr"
require "./database.cr"
require "./history.cr"
require "./ranks/authorized_ranks.cr"
require "./client.cr"
require "./relay/relay.cr"
require "./spam/spam_handler.cr"

module PrivateParlorXT
  # Container for all objects needed for handlers
  class Services
    getter config : HandlerConfig
    getter locale : Locale
    getter database : Database
    getter history : History
    getter access : AuthorizedRanks
    getter client : Client
    getter relay : Relay
    getter spam : SpamHandler? = nil

    def initialize(
      @config : HandlerConfig,
      @locale : Locale,
      @database : Database,
      @history : History,
      @access : AuthorizedRanks,
      @client : Client,
      @relay : Relay,
      @spam : SpamHandler?,
    )
    end
  end
end