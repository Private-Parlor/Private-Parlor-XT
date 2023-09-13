require "../constants.cr"
require "../history.cr"

module PrivateParlorXT
  class CachedHistory < History
    class MessageGroup
      getter sender : UserID = 0
      getter origin : MessageID = 0
      getter sent : Time = Time.utc
      property receivers : Hash(UserID, MessageID) = {} of UserID => MessageID
      property ratings : Set(Int64) = Set(Int64).new

      # Creates an instance of `MessageGroup`
      #
      # ## Arguments:
      #
      # `sender`
      # :     the id of the user who sent this message
      #
      # `msid`
      # :     the message ID returned when the message was sent successfully
      def initialize(@sender : UserID, @origin : MessageID)
      end
    end

    getter message_map : Hash(MessageID, MessageGroup) = {} of MessageID => MessageGroup

    def close
      message_map.clear
      Log.debug { "Explicitly cleared contents of message_map hash" }
    end

    # :inherit:
    def new_message(sender_id : UserID, origin : MessageID) : MessageID
      message = MessageGroup.new(sender_id, origin)
      @message_map.merge!({origin => message})
      origin
    end

    # :inherit:
    def add_to_history(origin : MessageID, receiver : MessageID, receiver_id : UserID) : Nil
      @message_map.merge!({receiver => @message_map[origin]})
      @message_map[origin].receivers.merge!({receiver_id => receiver})
    end

    # :inherit:
    def get_origin_message(message : MessageID) : MessageID?
      if msg = @message_map[message]?
        msg.origin
      end
    end

    # :inherit:
    def get_all_receivers(message : MessageID) : Hash(UserID, MessageID)
      if msg = @message_map[message]?
        {msg.sender => msg.origin}.merge!(msg.receivers)
      else
        {} of UserID => MessageID
      end
    end

    # :inherit:
    def get_receiver_message(message : MessageID, receiver : UserID) : MessageID?
      get_all_receivers(message)[receiver]?
    end

    # :inherit:
    def get_sender(message : MessageID) : UserID?
      if msg = @message_map[message]?
        msg.sender
      end
    end

    # :inherit:
    def get_messages_from_user(user : UserID) : Set(MessageID)
      user_msgs = Set(MessageID).new
      @message_map.each_value do |msg|
        if msg.sender != user
          next
        end

        user_msgs.add(msg.origin)
      end

      user_msgs
    end

    # :inherit:
    def add_rating(message : MessageID, user : UserID) : Bool
      @message_map[message].ratings.add?(user)
    end

    # Deletes a `MessageGroup` from the `message_map`
    def delete_message_group(message : MessageID) : MessageID?
      message = @message_map[message]

      message.receivers.each_value do |cached_msid|
        @message_map.delete(cached_msid)
      end
      @message_map.delete(message.origin)

      message.origin
    end

    # Returns true if the given message group is older than `lifespan`
    # Returns false otherwise
    private def expired?(message : MessageGroup) : Bool
      message.sent <= Time.utc - @lifespan
    end

    # :inherit:
    def expire : Nil
      msids = Set(MessageID).new

      @message_map.each_value do |message_group|
        if !expired?(message_group)
          next
        end

        msids << message_group.origin
      end

      msids.each do |msid|
        delete_message_group(msid)
      end

      if msids.size > 0
        Log.debug { "Expired #{msids.size} messages from the cache" }
      end
    end
  end
end
