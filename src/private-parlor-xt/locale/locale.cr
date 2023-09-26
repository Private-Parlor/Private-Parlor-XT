require "./replies.cr"
require "./logs.cr"
require "./command_descriptions.cr"
require "yaml"

module PrivateParlorXT
  struct Locale
    include YAML::Serializable

    @[YAML::Field(key: "time_units")]
    getter time_units : Array(String)

    @[YAML::Field(key: "time_format")]
    getter time_format : String

    @[YAML::Field(key: "toggle")]
    getter toggle : Array(String)

    @[YAML::Field(key: "loading_bar")]
    getter loading_bar : Array(String)
  end
end
