require "../constants.cr"
require "tourmaline"

module PrivateParlorXT

  # The proc associated with a `QueuedMessage`
  # 
  # A `MessageProc` can return the following types:
  #   - `Tourmaline::Message`: Functions that send text messages, photos, GIFs, and similar items will return a single `Tourmaline::Message`
  #   - `Array(Tourmaline::Message)`: Functions that send albums/media groups will return an array of the the sent `Tourmaline::Message`
  #   - `Bool`: Functions that delete, pin, or edit messages will return a `Bool`, where `true` represents a success and `false` represents a failure. 
  #     A `Bool` result is currently not useful to the bot.
  alias MessageProc = Proc(UserID, ReplyParameters?, Tourmaline::Message) |
                      Proc(UserID, ReplyParameters?, Array(Tourmaline::Message)) |
                      Proc(UserID, ReplyParameters?, Bool)

  # A queued message ready to be sent to Telegram
  class QueuedMessage
    # The message ID of the message group that this `QueuedMessage` originated from
    getter origin_msid : MessageID | Array(MessageID) | Nil

    # The sender of the message group from which this `QueuedMessage` originates
    # 
    # Set to `nil` for system messages
    getter sender : UserID?

    # User who will receive this `QueuedMessage`
    getter receiver : UserID

    # Data about the message this `QueuedMessage` replies to
    # 
    # Set to `nil` if this `QueuedMessage` does not reply to a message
    getter reply_to : ReplyParameters?

    # The proc that will run when this `QueuedMessage` is ready to be sent
    getter function : MessageProc

    # Creates an instance of `QueuedMessage`.
    def initialize(
      @origin_msid : MessageID | Array(MessageID) | Nil,
      @sender : UserID?,
      @receiver : UserID,
      @reply_to : ReplyParameters?,
      @function : MessageProc
    )
    end
  end
end
