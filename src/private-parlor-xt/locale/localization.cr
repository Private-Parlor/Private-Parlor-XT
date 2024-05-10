require "./locale.cr"
require "./replies.cr"
require "./logs.cr"
require "./command_descriptions.cr"
require "yaml"

module PrivateParlorXT

  # A container used for parsing the locale file and storing deserialized localization objects
  class Localization
    include YAML::Serializable

    @[YAML::Field(key: "locale")]
    # Returns the deserialized `Locale`
    getter locale : Locale

    @[YAML::Field(key: "replies")]
    # Returns the deserialized `Replies`
    getter replies : Replies

    @[YAML::Field(key: "logs")]
    # Returns the deserialized `Logs`
    getter logs : Logs

    @[YAML::Field(key: "command_descriptions")]
    # Returns the deserialized `CommandDescriptions`
    getter command_descriptions : CommandDescriptions

    # Parses a file corresponding to the given *language_code* from the locales folder
    def self.parse_locale(path : Path, language_code : String) : Localization
      Localization.from_yaml(File.open(path.join("#{language_code}.yaml")))
    rescue ex : YAML::ParseException
      Log.error(exception: ex) { "Could not parse the given value at row #{ex.line_number}. This could be because a required value was not set or the wrong type was given." }
      exit
    rescue ex : File::NotFoundError | File::AccessDeniedError
      Log.error(exception: ex) { "Could not open \"./locales/#{language_code}.yaml\". Exiting..." }
      exit
    end
  end
end
