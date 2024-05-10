require "./replies.cr"
require "./logs.cr"
require "./command_descriptions.cr"
require "yaml"

module PrivateParlorXT

  # A container for general localization values
  struct Locale
    include YAML::Serializable

    @[YAML::Field(key: "time_units")]
    # Returns an array of short time units from largest unit to smallest
    getter time_units : Array(String)

    @[YAML::Field(key: "time_format")]
    # Returns the format for timestamps
    getter time_format : String

    @[YAML::Field(key: "toggle")]
    # Returns an array of words for when a setting is turned off or on
    getter toggle : Array(String)

    @[YAML::Field(key: "loading_bar")]
    # Returns an array of pips for the loading bar from empty, partially full, to full
    getter loading_bar : Array(String)

    @[YAML::Field(key: "change")]
    # Returns an array of symbols for increasing and decreasing change
    getter change : Array(String)

    @[YAML::Field(key: "statistics_screens")]
    # Returns hash of `Statistics::StatScreens` to `String`, where the `String` contains the localized name for that `Statistics::StatScreens`
    getter statistics_screens : Hash(Statistics::StatScreens, String)
  end
end
