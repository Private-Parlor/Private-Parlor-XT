require "../constants.cr"
require "yaml"

module PrivateParlorXT
  class SpamHandler
    include YAML::Serializable

    getter scores : Hash(UserID, Int32) = {} of UserID => Int32
    getter sign_last_used : Hash(UserID, Time) = {} of UserID => Time
    getter upvote_last_used : Hash(UserID, Time) = {} of UserID => Time
    getter downvote_last_used : Hash(UserID, Time) = {} of UserID => Time

    @[YAML::Field(key: "spam_limit")]
    getter spam_limit : Int32 = 10000

    @[YAML::Field(key: "decay_amount")]
    getter decay_amount : Int32 = 1000

    @[YAML::Field(key: "score_character")]
    getter score_character : Int32 = 3

    @[YAML::Field(key: "score_line")]
    getter score_line : Int32 = 100

    @[YAML::Field(key: "score_animation")]
    getter score_animation : Int32 = 3000

    @[YAML::Field(key: "score_audio")]
    getter score_audio : Int32 = 3000

    @[YAML::Field(key: "score_document")]
    getter score_document : Int32 = 3000

    @[YAML::Field(key: "score_video")]
    getter score_video : Int32 = 3000

    @[YAML::Field(key: "score_video_note")]
    getter score_video_note : Int32 = 5000

    @[YAML::Field(key: "score_voice")]
    getter score_voice : Int32 = 5000

    @[YAML::Field(key: "score_photo")]
    getter score_photo : Int32 = 3000

    @[YAML::Field(key: "score_media_group")]
    getter score_media_group : Int32 = 6000

    @[YAML::Field(key: "score_poll")]
    getter score_poll : Int32 = 6000

    @[YAML::Field(key: "score_forwarded_message")]
    getter score_forwarded_message : Int32 = 3000

    @[YAML::Field(key: "score_sticker")]
    getter score_sticker : Int32 = 3000

    @[YAML::Field(key: "score_venue")]
    getter score_venue : Int32 = 5000

    @[YAML::Field(key: "score_location")]
    getter score_location : Int32 = 5000

    @[YAML::Field(key: "score_contact")]
    getter score_contact : Int32 = 5000

    def initialize(
      @scores : Hash(UserID, Int32) = {} of UserID => Int32,
      @sign_last_used : Hash(UserID, Time) = {} of UserID => Time,
      @upvote_last_used : Hash(UserID, Time) = {} of UserID => Time,
      @downvote_last_used : Hash(UserID, Time) = {} of UserID => Time,
      @spam_limit : Int32 = 10000,
      @decay_amount : Int32 = 1000,
      @score_character : Int32 = 3,
      @score_line : Int32 = 100,
      @score_animation : Int32 = 3000,
      @score_audio : Int32 = 3000,
      @score_document : Int32 = 3000,
      @score_video : Int32 = 3000,
      @score_video_note : Int32 = 5000,
      @score_voice : Int32 = 5000,
      @score_photo : Int32 = 3000,
      @score_media_group : Int32 = 6000,
      @score_poll : Int32 = 6000,
      @score_forwarded_message : Int32 = 3000,
      @score_sticker : Int32 = 3000,
      @score_venue : Int32 = 5000,
      @score_location : Int32 = 5000,
      @score_contact : Int32 = 5000,
    )
    end

    # Check if user's spam score will exceed the limit
    #
    # Returns true if score is greater than spam limit, false otherwise.
    private def spammy?(user : UserID, increment : Int32) : Bool
      score = 0 unless score = @scores[user]?

      if score > spam_limit || score + increment > spam_limit
        return true
      end

      @scores[user] = score + increment

      false
    end

    # Check if user has signed within an interval of time
    #
    # Returns true if so (user is sign spamming), false otherwise.
    def spammy_sign?(user : UserID, interval : Int32) : Bool
      unless interval == 0
        if last_used = @sign_last_used[user]?
          if (Time.utc - last_used) < interval.seconds
            return true
          else
            @sign_last_used[user] = Time.utc
          end
        else
          @sign_last_used[user] = Time.utc
        end
      end

      false
    end

    # Check if user has upvoted within an interval of time
    #
    # Returns true if so (user is upvoting too often), false otherwise.
    def spammy_upvote?(user : UserID, interval : Int32) : Bool
      unless interval == 0
        if last_used = @upvote_last_used[user]?
          if (Time.utc - last_used) < interval.seconds
            return true
          else
            @upvote_last_used[user] = Time.utc
          end
        else
          @upvote_last_used[user] = Time.utc
        end
      end

      false
    end

    # Check if user has downvoted within an interval of time
    #
    # Returns true if so (user is downvoting too often), false otherwise.
    def spammy_downvote?(user : UserID, interval : Int32) : Bool
      unless interval == 0
        if last_used = @downvote_last_used[user]?
          if (Time.utc - last_used) < interval.seconds
            return true
          else
            @downvote_last_used[user] = Time.utc
          end
        else
          @downvote_last_used[user] = Time.utc
        end
      end

      false
    end

    def spammy_text?(user : UserID, text : String) : Bool
      spammy?(user, (text.size * score_character) + (text.lines.size * score_line))
    end

    def spammy_photo?(user : UserID) : Bool
      spammy?(user, score_photo)
    end

    def spammy_animation?(user : UserID) : Bool
      spammy?(user, score_animation)
    end

    def spammy_video?(user : UserID) : Bool
      spammy?(user, score_video)
    end

    def spammy_audio?(user : UserID) : Bool
      spammy?(user, score_audio)
    end

    def spammy_voice?(user : UserID) : Bool
      spammy?(user, score_voice)
    end

    def spammy_document?(user : UserID) : Bool
      spammy?(user, score_document)
    end

    def spammy_poll?(user : UserID) : Bool
      spammy?(user, score_poll)
    end

    def spammy_forward?(user : UserID) : Bool
      spammy?(user, score_forwarded_message)
    end

    def spammy_video_note?(user : UserID) : Bool
      spammy?(user, score_video_note)
    end

    def spammy_sticker?(user : UserID) : Bool
      spammy?(user, score_sticker)
    end

    def spammy_album?(user : UserID) : Bool
      spammy?(user, score_media_group)
    end

    def spammy_venue?(user : UserID) : Bool
      spammy?(user, score_venue)
    end

    def spammy_location?(user : UserID) : Bool
      spammy?(user, score_location)
    end

    def spammy_contact?(user : UserID) : Bool
      spammy?(user, score_contact)
    end

    def expire
      @scores.each do |user, score|
        if (score - @decay_amount) <= 0
          @scores.delete(user)
        else
          @scores[user] = score - @decay_amount
        end
      end
    end
  end
end
