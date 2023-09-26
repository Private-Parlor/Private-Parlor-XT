require "./rank.cr"
require "./command_permissions.cr"
require "./message_permissions.cr"

module PrivateParlorXT
  class AuthorizedRanks
    getter ranks : Hash(Int32, Rank)

    def initialize(@ranks : Hash(Int32, Rank))
    end

    # Returns `true` if user rank has the given command permission; user is authorized.
    #
    # Returns `false` otherwise, or `nil` if the user rank does not exist in `ranks`
    def authorized?(user_rank : Int32, permission : CommandPermissions) : Bool?
      if rank = @ranks[user_rank]?
        rank.command_permissions.includes?(permission)
      end
    end

    # Returns the first symbol found from intersecting the user command permissions and the given permissions; user is authorized.
    #
    # Returns`nil` if the user rank does not exist in `ranks` or if the rank does not have any of the given permissions.
    #
    # Used for checking groups of command permissions that are similar.
    def authorized?(user_rank : Int32, *permissions : CommandPermissions) : CommandPermissions?
      if rank = @ranks[user_rank]?
        (rank.command_permissions & permissions.to_set).first?
      end
    end

    # Returns `true` if user rank has the given message permission; user is authorized.
    #
    # Returns `false` otherwise, or `nil` if the user rank does not exist in `ranks`
    def authorized?(user_rank : Int32, permission : MessagePermissions) : Bool?
      if rank = @ranks[user_rank]?
        rank.message_permissions.includes?(permission)
      end
    end

    # Returns the max rank value in the ranks hash
    def max_rank : Int32
      @ranks.keys.max
    end

    # Returns the rank name associated with the given value.
    def rank_name(rank_value : Int32) : String?
      if @ranks[rank_value]?
        @ranks[rank_value].name
      end
    end

    # Return an array of rank names that have a ranksay permission
    def ranksay_ranks : Array(String)
      names = [] of String

      ranksay_permissions = Set{
        CommandPermissions::Ranksay,
        CommandPermissions::RanksayLower,
      }

      @ranks.each do |_, rank|
        if ranksay_permissions.intersects?(rank.command_permissions)
          names << rank.name
        end
      end

      names
    end

    # Finds a rank from a given rank value
    # or iterates through the ranks hash for a rank with a given name
    #
    # Returns a 2-tuple with the rank value and the rank associated with that rank,
    # or `nil` if no rank exists with the given values.
    def find_rank(name : String, value : Int32? = nil) : Tuple(Int32, Rank)?
      if value && @ranks[value]?
        {value, @ranks[value]}
      else
        @ranks.find do |k, v|
          v.name.downcase == name || k == value
        end
      end
    end

    # Returns true if the user to be promoted (receiver) can be promoted with the given rank.
    def can_promote?(rank : Int32, invoker : Int32, receiver : Int32, permission : CommandPermissions) : Bool
      if rank <= receiver || rank > invoker || rank == -10
        return false
      end

      if rank <= invoker && permission == CommandPermissions::Promote
        true
      elsif rank < invoker && permission == CommandPermissions::PromoteLower
        true
      elsif rank == invoker && permission == CommandPermissions::PromoteSame
        true
      else
        false
      end
    end

    # Returns `true` if the user to be demoted (receiver) can be demoted with the given rank.
    def can_demote?(rank : Int32, invoker : Int32, receiver : Int32) : Bool
      rank < receiver && receiver < invoker && rank != -10
    end

    # Returns `true` if the user can sign a message with the given rank.
    def can_ranksay?(rank : Int32, invoker : Int32, invoker_permission : CommandPermissions, rank_permission : CommandPermissions? = nil) : Bool
      return false if rank == -10 || rank_permission.nil?

      (rank < invoker && invoker_permission == CommandPermissions::RanksayLower) || rank == invoker
    end

    # Returns an array of all the rank names in the ranks hash.
    def rank_names : Array(String)
      @ranks.compact_map do |_, v|
        v.name
      end
    end

    # Returns an array of all the rank names in the ranks hash, up to a rank value limit.
    def rank_names(limit : Int32) : Array(String)
      @ranks.compact_map do |k, v|
        v.name if k <= limit
      end
    end
  end
end
