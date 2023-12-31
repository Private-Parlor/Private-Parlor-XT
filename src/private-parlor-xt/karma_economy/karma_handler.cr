require "yaml"

module PrivateParlorXT
  class KarmaHandler
    include YAML::Serializable

    @[YAML::Field(key: "cutoff_rank")]
    getter cutoff_rank : Int32 = 10

    @[YAML::Field(key: "karma_text")]
    getter karma_text  : Int32 = 0

    @[YAML::Field(key: "karma_animation")]
    getter karma_animation : Int32 = 5

    @[YAML::Field(key: "karma_audio")]
    getter karma_audio : Int32 = 2

    @[YAML::Field(key: "karma_document")]
    getter karma_document : Int32 = 2

    @[YAML::Field(key: "karma_video")]
    getter karma_video : Int32 = 10

    @[YAML::Field(key: "karma_video_note")]
    getter karma_video_note : Int32 = 10

    @[YAML::Field(key: "karma_voice")]
    getter karma_voice : Int32 = 2

    @[YAML::Field(key: "karma_photo")]
    getter karma_photo : Int32 = 5

    @[YAML::Field(key: "karma_media_group")]
    getter karma_media_group : Int32 = 10

    @[YAML::Field(key: "karma_poll")]
    getter karma_poll : Int32 = 20

    @[YAML::Field(key: "karma_forwarded_message")]
    getter karma_forwarded_message : Int32 = 10

    @[YAML::Field(key: "karma_sticker")]
    getter karma_sticker : Int32 = 2

    @[YAML::Field(key: "karma_venue")]
    getter karma_venue : Int32 = 10

    @[YAML::Field(key: "karma_location")]
    getter karma_location : Int32 = 10

    @[YAML::Field(key: "karma_contact")]
    getter karma_contact : Int32 = 10
  end
end