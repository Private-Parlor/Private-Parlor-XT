require "yaml"

module PrivateParlorXT
  # A module that requires users to have a certain amount of karma before sending a message
  #
  # Each message has a specific among of karma necessary before a message of that type can be sent.
  # If a message of that type is sent, the amount for that type will be deducted from the user's karma.
  class KarmaHandler
    include YAML::Serializable

    @[YAML::Field(key: "cutoff_rank")]
    # The value of the `Rank` at which users of this `Rank` and above do not have to spend karma to post messages
    getter cutoff_rank : Int32 = 10

    @[YAML::Field(key: "karma_text")]
    # The amount of karma necessary to post a text message
    getter karma_text : Int32 = 0

    @[YAML::Field(key: "karma_animation")]
    # The amount of karma necessary to post a GIF
    getter karma_animation : Int32 = 5

    @[YAML::Field(key: "karma_audio")]
    # The amount of karma necessary to post an audio message
    getter karma_audio : Int32 = 2

    @[YAML::Field(key: "karma_document")]
    # The amount of karma necessary to post a file
    getter karma_document : Int32 = 2

    @[YAML::Field(key: "karma_video")]
    # The amount of karma necessary to post a video
    getter karma_video : Int32 = 10

    @[YAML::Field(key: "karma_video_note")]
    # The amount of karma necessary to post a video note
    getter karma_video_note : Int32 = 10

    @[YAML::Field(key: "karma_voice")]
    # The amount of karma necessary to post a voice message
    getter karma_voice : Int32 = 2

    @[YAML::Field(key: "karma_photo")]
    # The amount of karma necessary to post a photo
    getter karma_photo : Int32 = 5

    @[YAML::Field(key: "karma_media_group")]
    # The amount of karma necessary to post an album
    getter karma_media_group : Int32 = 10

    @[YAML::Field(key: "karma_poll")]
    # The amount of karma necessary to post a poll
    getter karma_poll : Int32 = 20

    @[YAML::Field(key: "karma_forwarded_message")]
    # The amount of karma necessary to post a forwarded message
    getter karma_forwarded_message : Int32 = 10

    @[YAML::Field(key: "karma_sticker")]
    # The amount of karma necessary to post a sticker
    getter karma_sticker : Int32 = 2

    @[YAML::Field(key: "karma_venue")]
    # The amount of karma necessary to post a venue
    getter karma_venue : Int32 = 10

    @[YAML::Field(key: "karma_location")]
    # The amount of karma necessary to post a location
    getter karma_location : Int32 = 10

    @[YAML::Field(key: "karma_contact")]
    # The amount of karma necessary to post a contact
    getter karma_contact : Int32 = 10

    def initialize(
      @cutoff_rank : Int32 = 10,
      @karma_text : Int32 = 0,
      @karma_animation : Int32 = 5,
      @karma_audio : Int32 = 2,
      @karma_document : Int32 = 2,
      @karma_video : Int32 = 10,
      @karma_video_note : Int32 = 10,
      @karma_voice : Int32 = 2,
      @karma_photo : Int32 = 5,
      @karma_media_group : Int32 = 10,
      @karma_poll : Int32 = 20,
      @karma_forwarded_message : Int32 = 10,
      @karma_sticker : Int32 = 2,
      @karma_venue : Int32 = 10,
      @karma_location : Int32 = 10,
      @karma_contact : Int32 = 10
    )
    end
  end
end
