module PrivateParlorXT
  # TODO: Update this alias
  alias MessageProc = Nil

  class QueuedMessage
    getter origin_msid : Int64 | Array(Int64) | Nil
    getter sender : Int64 | Nil
    getter receiver : Int64
    getter reply_to : Int64 | Nil
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
      @origin_msid : Int64 | Array(Int64) | Nil,
      @sender : Int64 | Nil,
      @receiver : Int64,
      @reply_to : Int64 | Nil,
      @function : MessageProc
    )
    end
  end
end