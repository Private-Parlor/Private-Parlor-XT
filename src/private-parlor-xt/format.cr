require "tourmaline"

module PrivateParlorXT
  module Format
    include Tourmaline::Helpers
    extend self

    # Globally substitutes placeholders in message with the given variables
    def substitute_message(msg : String, locale : Locale, variables : Hash(String, String?) = {"" => ""}) : String
      msg.gsub(/{\w+}/) do |match|
        escape_html(variables[match[1..-2]])
      end
    end

    def format_reason_reply(reason : String?, locale : Locale) : String?
      if reason
        "#{locale.replies.reason_prefix}#{reason}"
      end
    end

    def format_contact_reply(contact : String?, locale : Locale) : String?
      if contact
        locale.replies.blacklist_contact.gsub("{contact}", "#{escape_html(contact)}")
      end
    end

  end
end