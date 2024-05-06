require "./constants.cr"

module PrivateParlorXT

  # A base class for objects that store the history of sent messages so that they can be referenced later for replies, deletions, or other commands
  abstract class History
    # Returns the `Time::Span` for which a message can exist before expiring
    getter lifespan : Time::Span = 24.hours

    # Initialize a message `History` where messages older than `lifespan` are considered expired
    def initialize(@lifespan : Time::Span)
    end

    # Cleanup when finished with `History`
    #
    # Mainly applicable for implementations using a database
    def close
    end

    # Create a new message group and add it to the `History`
    abstract def new_message(sender_id : UserID, origin : MessageID) : MessageID

    # Add a receiver message to the `History`
    abstract def add_to_history(origin : MessageID, receiver : MessageID, receiver_id : UserID) : Nil

    # Get the message ID of the original message associated with the given message ID
    abstract def get_origin_message(message : MessageID) : MessageID?

    # Get a hash of all users and receiver message IDs associated with the given message ID
    abstract def get_all_receivers(message : MessageID) : Hash(UserID, MessageID)

    # Get the original message ID associated with the given message ID and receiver ID
    abstract def get_receiver_message(message : MessageID, receiver : UserID) : MessageID?

    # Get the sender of the original message referenced by the given message ID
    abstract def get_sender(message : MessageID) : UserID?

    # Get all message IDs sent by a given user for purging messages
    abstract def get_messages_from_user(user : UserID) : Set(MessageID)

    # Adds a rating entry to the database with the given data
    #
    # Returns `true` if the user's rating was successfully added; `false` if the user's rating already exists.
    abstract def add_rating(message : MessageID, user : UserID) : Bool

    # Adds a warning to the given message
    abstract def add_warning(message : MessageID) : Nil

    # Returns `true` if the given message was already warned; `false` or nil otherwise
    abstract def get_warning(message : MessageID) : Bool?

    # Get a hash containing an array of message IDs to delete associated with the users who received a message in the given set.
    # Used for the `PurgeCommand`
    # NOTE: The returned array of message IDs should be sorted in descending order (most recent messages first)
    abstract def get_purge_receivers(messages : Set(MessageID)) : Hash(UserID, Array(MessageID))

    # Delete a message group from the `History`
    abstract def delete_message_group(message : MessageID) : MessageID?

    # Deletes old messages from the `History`
    #
    # This should be invoked as a recurring task
    abstract def expire : Nil
  end
end
