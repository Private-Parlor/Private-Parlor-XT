require "../constants.cr"
require "tourmaline"

module PrivateParlorXT
  alias MessageProc = Proc(UserID, MessageID?, Tourmaline::Message) | 
                      Proc(UserID, MessageID?, Array(Tourmaline::Message)) |
                      Proc(UserID, MessageID?, Bool)

  class QueuedMessage
    getter origin_msid : MessageID | Array(MessageID) | Nil
    getter sender : UserID?
    getter receiver : UserID
    getter reply_to : MessageID?
    getter function : MessageProc

    # Creates an instance of `QueuedMessage`.
    #
    # ## Arguments:
    #
    # `hash`
    # :     a hashcode that refers to the associated `MessageGroup` stored in the message history.
    #
    # `sender`
    # :     the ID of the user who sent this message.
    #
    # `receiver_id`
    # :     the ID of the user who will receive this message.
    #
    # `reply_msid`
    # :     the MSID of a message to reply to. May be `nil` if this message isn't a reply.
    #
    # `function`
    # :     a proc that points to a Tourmaline CoreMethod send function and takes a user ID and MSID as its arguments
    def initialize(
      @origin_msid : MessageID | Array(MessageID) | Nil,
      @sender : UserID?,
      @receiver : UserID,
      @reply_to : MessageID?,
      @function : MessageProc
    )
    end
  end
end
