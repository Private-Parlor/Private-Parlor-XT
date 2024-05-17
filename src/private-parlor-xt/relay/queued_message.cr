require "../constants.cr"
require "tourmaline"

module PrivateParlorXT
  # A queued message ready to be sent to Telegram
  class QueuedMessage
    # The message ID of the message group that this `QueuedMessage` originated from
    getter origin : MessageID | Array(MessageID) | Nil

    # The sender of the message group from which this `QueuedMessage` originates
    #
    # Set to `nil` for system messages
    getter sender : UserID?

    # User who will receive this `QueuedMessage`
    getter receiver : UserID

    # Data about the message this `QueuedMessage` replies to
    #
    # Set to `nil` if this `QueuedMessage` does not reply to a message
    getter reply : ReplyParameters?

    # The proc that will run when this `QueuedMessage` is ready to be sent
    getter function : MessageProc

    # Creates an instance of `QueuedMessage`.
    def initialize(
      @origin : MessageID | Array(MessageID) | Nil,
      @sender : UserID?,
      @receiver : UserID,
      @reply : ReplyParameters?,
      @function : MessageProc
    )
    end
  end
end
