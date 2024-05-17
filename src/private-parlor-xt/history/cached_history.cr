require "../constants.cr"
require "../history.cr"

module PrivateParlorXT

  # An implementation of `History` storing the messages in RAM as a `Hash`
  class CachedHistory < History

    # Represents single message sent and all of its receivers
    class MessageGroup
      # User who sent this message
      getter sender : UserID = 0

      # The original message ID of this message
      getter origin : MessageID = 0

      # The time at which this message was sent
      getter sent : Time = Time.utc

      # Users who received this message and their corresponding `MessageID`
      property receivers : Hash(UserID, MessageID) = {} of UserID => MessageID

      # Set of users who upvoted or downvoted this message
      property ratings : Set(UserID) = Set(UserID).new

      # Whether or not this message has been warned
      # 
      # If `true`, a warning has been given to the user who sent this message, `false` otherwise
      property warned : Bool? = false

      # Creates an instance of `MessageGroup`
      def initialize(@sender : UserID, @origin : MessageID)
      end
    end

    # A hash of `MessageID` to `MessageGroup`
    getter message_map : Hash(MessageID, MessageGroup) = {} of MessageID => MessageGroup

    # :inherit:
    def close
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
    def origin_message(message : MessageID) : MessageID?
      if msg = @message_map[message]?
        msg.origin
      end
    end

    # :inherit:
    def receivers(message : MessageID) : Hash(UserID, MessageID)
      if msg = @message_map[message]?
        {msg.sender => msg.origin}.merge!(msg.receivers)
      else
        {} of UserID => MessageID
      end
    end

    # :inherit:
    def receiver_message(message : MessageID, receiver : UserID) : MessageID?
      receivers(message)[receiver]?
    end

    # :inherit:
    def sender(message : MessageID) : UserID?
      if msg = @message_map[message]?
        msg.sender
      end
    end

    # :inherit:
    def messages_from_user(user : UserID) : Set(MessageID)
      user_msgs = Set(MessageID).new
      @message_map.each_value do |msg|
        next unless msg.sender == user

        next if msg.sent <= Time.utc - 48.hours

        user_msgs.add(msg.origin)
      end

      user_msgs
    end

    # :inherit:
    def add_rating(message : MessageID, user : UserID) : Bool
      @message_map[message].ratings.add?(user)
    end

    # :inherit:
    def add_warning(message : MessageID) : Nil
      if msg = @message_map[message]
        msg.warned = true
      end
    end

    # :inherit:
    def warned?(message : MessageID) : Bool?
      if msg = @message_map[message]
        msg.warned
      end
    end

    # :inherit:
    def purge_receivers(messages : Set(MessageID)) : Hash(UserID, Array(MessageID))
      hash = {} of UserID => Array(MessageID)

      messages = messages.to_a.sort { |a, b| b <=> a }

      messages.each do |msid|
        @message_map[msid].receivers.each do |receiver, receiver_msid|
          if hash[receiver]?
            hash[receiver] << receiver_msid
          else
            hash[receiver] = [receiver_msid]
          end
        end
      end

      hash
    end

    # :inherit:
    def delete_message_group(message : MessageID) : MessageID?
      message = @message_map[message]

      message.receivers.each_value do |cached_msid|
        @message_map.delete(cached_msid)
      end
      @message_map.delete(message.origin)

      message.origin
    end

    # Returns `true` if the given message group is older than `lifespan`
    # 
    # Returns `false` otherwise
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
