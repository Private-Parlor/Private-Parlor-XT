require "../constants.cr"
require "yaml"

module PrivateParlorXT

  # A module used for keeping track of the frequency of a user's message posting in order to prevent spam
  class SpamHandler
    include YAML::Serializable

    # Returns a hash of `UserID` to `Int32`, contaning the scores for each user
    getter scores : Hash(UserID, Int32) = {} of UserID => Int32

    # Returns a hash of `UserID` to `Time`, contaning the time each user last signed
    getter sign_last_used : Hash(UserID, Time) = {} of UserID => Time

    # Returns a hash of `UserID` to `Time`, contaning the time each user last upvoted
    getter upvote_last_used : Hash(UserID, Time) = {} of UserID => Time

    # Returns a hash of `UserID` to `Time`, contaning the time each user last downvoted
    getter downvote_last_used : Hash(UserID, Time) = {} of UserID => Time

    @[YAML::Field(key: "spam_limit")]
    # The limit for spam scores that, when hit, prevents the user from sending another message until it decays
    getter spam_limit : Int32 = 10000

    @[YAML::Field(key: "decay_amount")]
    # The amount at which spam scores decay
    getter decay_amount : Int32 = 1000

    @[YAML::Field(key: "score_character")]
    # Amount added to the score for each character in text
    getter score_character : Int32 = 3

    @[YAML::Field(key: "score_line")]
    # Amount added to the score for each line in text
    getter score_line : Int32 = 100

    @[YAML::Field(key: "score_text")]
    # Amount added to the score for each text message
    getter score_text : Int32 = 2000

    @[YAML::Field(key: "score_animation")]
    # Amount added to the score for each animation
    getter score_animation : Int32 = 3000

    @[YAML::Field(key: "score_audio")]
    # Amount added to the score for each audio
    getter score_audio : Int32 = 3000

    @[YAML::Field(key: "score_document")]
    # Amount added to the score for each document
    getter score_document : Int32 = 3000

    @[YAML::Field(key: "score_video")]
    # Amount added to the score for each video
    getter score_video : Int32 = 3000

    @[YAML::Field(key: "score_video_note")]
    # Amount added to the score for each video note
    getter score_video_note : Int32 = 5000

    @[YAML::Field(key: "score_voice")]
    # Amount added to the score for each voice message
    getter score_voice : Int32 = 5000

    @[YAML::Field(key: "score_photo")]
    # Amount added to the score for each photo
    getter score_photo : Int32 = 3000

    @[YAML::Field(key: "score_media_group")]
    # Amount added to the score for each album
    getter score_media_group : Int32 = 6000

    @[YAML::Field(key: "score_poll")]
    # Amount added to the score for each poll
    getter score_poll : Int32 = 6000

    @[YAML::Field(key: "score_forwarded_message")]
    # Amount added to the score for each forwarded message
    getter score_forwarded_message : Int32 = 3000

    @[YAML::Field(key: "score_sticker")]
    # Amount added to the score for each sticker
    getter score_sticker : Int32 = 3000

    @[YAML::Field(key: "score_venue")]
    # Amount added to the score for each venue
    getter score_venue : Int32 = 5000

    @[YAML::Field(key: "score_location")]
    # Amount added to the score for each location
    getter score_location : Int32 = 5000

    @[YAML::Field(key: "score_contact")]
    # Amount added to the score for each contact
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
      @score_text : Int32 = 2000,
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
      @score_contact : Int32 = 5000
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

    # Returns `true` if the text message was spammy
    # 
    # Returns `false` otherwise
    def spammy_text?(user : UserID, text : String) : Bool
      spammy?(user, score_text + (text.size * score_character) + (text.lines.size * score_line))
    end

    # Returns `true` if the photo was spammy
    # 
    # Returns `false` otherwise
    def spammy_photo?(user : UserID) : Bool
      spammy?(user, score_photo)
    end

    # Returns `true` if the animation was spammy
    # 
    # Returns `false` otherwise
    def spammy_animation?(user : UserID) : Bool
      spammy?(user, score_animation)
    end

    # Returns `true` if the video was spammy
    # 
    # Returns `false` otherwise
    def spammy_video?(user : UserID) : Bool
      spammy?(user, score_video)
    end

    # Returns `true` if the audio was spammy
    # 
    # Returns `false` otherwise
    def spammy_audio?(user : UserID) : Bool
      spammy?(user, score_audio)
    end

    # Returns `true` if the voice message was spammy
    # 
    # Returns `false` otherwise
    def spammy_voice?(user : UserID) : Bool
      spammy?(user, score_voice)
    end

    # Returns `true` if the document was spammy
    # 
    # Returns `false` otherwise
    def spammy_document?(user : UserID) : Bool
      spammy?(user, score_document)
    end

    # Returns `true` if the poll was spammy
    # 
    # Returns `false` otherwise
    def spammy_poll?(user : UserID) : Bool
      spammy?(user, score_poll)
    end

    # Returns `true` if the forwarded message was spammy
    # 
    # Returns `false` otherwise
    def spammy_forward?(user : UserID) : Bool
      spammy?(user, score_forwarded_message)
    end

    # Returns `true` if the video note was spammy
    # 
    # Returns `false` otherwise
    def spammy_video_note?(user : UserID) : Bool
      spammy?(user, score_video_note)
    end

    # Returns `true` if the sticker was spammy
    # 
    # Returns `false` otherwise
    def spammy_sticker?(user : UserID) : Bool
      spammy?(user, score_sticker)
    end

    # Returns `true` if the album was spammy
    # 
    # Returns `false` otherwise
    def spammy_album?(user : UserID) : Bool
      spammy?(user, score_media_group)
    end

    # Returns `true` if the venue was spammy
    # 
    # Returns `false` otherwise
    def spammy_venue?(user : UserID) : Bool
      spammy?(user, score_venue)
    end

    # Returns `true` if the location was spammy
    # 
    # Returns `false` otherwise
    def spammy_location?(user : UserID) : Bool
      spammy?(user, score_location)
    end

    # Returns `true` if the contact was spammy
    # 
    # Returns `false` otherwise
    def spammy_contact?(user : UserID) : Bool
      spammy?(user, score_contact)
    end

    # Subtracts the `decay_amount` from the scores of each user in `scores`
    def expire : Nil
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
