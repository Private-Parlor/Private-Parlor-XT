require "./replies.cr"
require "./logs.cr"
require "./command_descriptions.cr"
require "yaml"

module PrivateParlorXT
  class Locale
    include YAML::Serializable

    @[YAML::Field(key: "time_units")]
    getter time_units : Array(String)

    @[YAML::Field(key: "time_format")]
    getter time_format : String

    @[YAML::Field(key: "toggle")]
    getter toggle : Array(String)

    @[YAML::Field(key: "loading_bar")]
    getter loading_bar : Array(String)

    @[YAML::Field(key: "replies")]
    getter replies : Replies

    @[YAML::Field(key: "logs")]
    getter logs : Logs

    @[YAML::Field(key: "command_descriptions")]
    getter command_descriptions : CommandDescriptions

    def self.parse_locale(language_code : String) : Locale
      Locale.from_yaml(File.open("./locales/#{language_code}.yaml"))
    rescue ex : YAML::ParseException
      Log.error(exception: ex) { "Could not parse the given value at row #{ex.line_number}. This could be because a required value was not set or the wrong type was given." }
      exit
    rescue ex : File::NotFoundError | File::AccessDeniedError
      Log.error(exception: ex) { "Could not open \"./locales/#{language_code}.yaml\". Exiting..." }
      exit
    end
  end
end