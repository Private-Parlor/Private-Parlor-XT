require "./command_permissions.cr"
require "./message_permissions.cr"
require "yaml"

module PrivateParlorXT
  # Represents a `Rank` which a user may belong to
  class Rank
    include YAML::Serializable

    # Name of this rank
    getter name : String

    # The set of commands and types of commands members of this rank can use
    getter command_permissions : Set(CommandPermissions)

    # The set of message types members of this rank can send
    getter message_permissions : Set(MessagePermissions)

    # Creates and instance of `Rank`
    def initialize(@name, @command_permissions, @message_permissions)
    end
  end
end
