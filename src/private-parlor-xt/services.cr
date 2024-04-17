require "./config/handler_config.cr"
require "./locale/*"
require "./database.cr"
require "./history.cr"
require "./ranks/authorized_ranks.cr"
require "./client.cr"
require "./relay/relay.cr"
require "./spam/spam_handler.cr"

module PrivateParlorXT
  # Container for all objects needed for handlers
  struct Services
    getter config : HandlerConfig
    getter locale : Locale
    getter replies : Replies
    getter logs : Logs
    getter command_descriptions : CommandDescriptions
    getter database : Database
    getter history : History
    getter access : AuthorizedRanks
    getter relay : Relay
    getter spam : SpamHandler?
    getter robot9000 : Robot9000?
    getter karma : KarmaHandler?
    getter stats : Statistics?

    def initialize(
      @config : HandlerConfig,
      @locale : Locale,
      @replies : Replies,
      @logs : Logs,
      @command_descriptions : CommandDescriptions,
      @database : Database,
      @history : History,
      @access : AuthorizedRanks,
      @relay : Relay,
      @spam : SpamHandler? = nil,
      @robot9000 : Robot9000? = nil,
      @karma : KarmaHandler? = nil,
      @stats : Statistics? = nil
    )
    end
  end
end
