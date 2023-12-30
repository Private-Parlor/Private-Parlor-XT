require "../spec_helper.cr"

module PrivateParlorXT
  class MockQueuedMessage < QueuedMessage
    getter data : String
    getter entities : Array(Tourmaline::MessageEntity)

    def initialize(
      @origin_msid : MessageID | Array(MessageID) | Nil,
      @sender : UserID?,
      @receiver : UserID,
      @reply_to : ReplyParameters?,
      @function : MessageProc,
      @data : String,
      @entities : Array(Tourmaline::MessageEntity)
    )
    end
  end
end
