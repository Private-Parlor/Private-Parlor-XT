require "./constants.cr"

module PrivateParlorXT
  abstract class History
    @lifespan : Time::Span = 24.hours

    # Initialize a message history where messages older than `lifespan` are considered expired
    private def initialize(@lifespan : Time::Span)
    end

    # Return the current instance of History
    #
    # There should only be one instance throughout the lifetime of the process
    def self.instance(lifespan : Time::Span)
      @@instance ||= new(lifespan)
    end

    # Cleanup when finished with History
    #
    # Mainly applicable for database implementation
    def close
    end

    # Create a new message group and add it to the history
    abstract def new_message(sender_id : UserID, origin : MessageID) : MessageID

    # Add a receiver message to the history
    abstract def add_to_history(origin : MessageID, receiver : MessageID, receiver_id : UserID) : Nil

    # Get the message ID of the original message associated with the given message ID
    abstract def get_origin_message(message : MessageID) : MessageID?

    # Get a hash of all users and receiver message IDs associated with the given message ID
    abstract def get_all_receivers(message : MessageID) : Hash(UserID, MessageID)

    # Get the original message ID associated with the given message ID and receiver ID
    abstract def get_receiver_message(message : MessageID, receiver : UserID) : MessageID?

    # Get the sender of the original message referenced by the given message ID
    abstract def get_sender(message : MessageID) : UserID?

    # Get all message IDs sent by a given user
    abstract def get_messages_from_user(user : UserID) : Set(MessageID)

    # Delete a message group from the history
    abstract def delete_message_group(message : MessageID) : MessageID?

    # Deletes old messages from the history
    #
    # This should be invoked as a recurring task
    abstract def expire : Nil
  end
end
