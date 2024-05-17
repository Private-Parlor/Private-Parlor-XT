require "./command_handler.cr"
require "./hears_handler.cr"
require "./update_handler.cr"
require "./services.cr"
require "tasker"

module PrivateParlorXT
  # Initialize bot handlers, such as `CommandHandler`, `HearsHandler`, `CallbackHandler`, and `UpdateHandler`
  def self.initialize_handlers(client : Tourmaline::Client, config : Config, services : Services) : Nil
    events = [] of Tourmaline::EventHandler

    events = events.concat(generate_command_handlers(config, client, services))

    events = events.concat(generate_hears_handlers(config, services))

    events = events.concat(generate_callback_query_handlers(config, services))

    # TODO: Add Inline Queries

    events.each do |handler|
      client.register(handler)
    end

    generate_update_handlers(config, client, services)
  end

  # Iterate through all `CommandHandler` subclasses and initialize `Tourmaline::CommandHandler` procs for these commands.
  #
  # `CommandDescriptions` for each `CommandHandler` will be registered by the bot if the the command is configurable.
  macro create_command_handlers
    {% for command in CommandHandler.all_subclasses.select { |sub_class|
                        (responds_to = sub_class.annotation(RespondsTo))
                      } %}

      {% responds_to = command.annotation(RespondsTo) %}

      {% if responds_to[:config].nil? %}
        {{warning %(Command #{command} should have a configuration toggle and command description.)}}
        append_command_handler({{command}}, {{responds_to[:command]}})
      {% else %}
        if config.{{responds_to[:config].id}}[0]
          append_command_handler({{command}}, {{responds_to[:command]}})
        else
          arr << Tourmaline::CommandHandler.new({{responds_to[:command]}}) do |ctx|
            next unless message = ctx.message
            next if message.date == 0 # Message is inaccessible

            message = message.as(Tourmaline::Message)

            command_disabled(message, services)
          end
        end

        if config.{{responds_to[:config].id}}[1]
          bot_commands << Tourmaline::BotCommand.new(
            {% if responds_to[:command].is_a?(ArrayLiteral) %}
              {{responds_to[:command][0]}},
              services.descriptions.{{responds_to[:command][0].id}}
            {% else %}
              {{responds_to[:command]}},
              services.descriptions.{{responds_to[:command].id}}
            {% end %}
          )
        end
      {% end %}

    {% end %}
  end

  # Appends given `CommandHandler` to `Tourmaline::CommandHandler` array
  #
  # The given `CommandHandler` will respond to *command* value(s) of `RespondsTo`
  macro append_command_handler(command, call)
    commands = [] of String

    {% if call.is_a?(ArrayLiteral) %}
      commands = commands + {{call}}
      {{handler = (call[0] + "_command").id}} = {{command}}.new(config)
    {% else %}
      commands << {{call}}
      {{handler = (call + "_command").id}}  = {{command}}.new(config)
    {% end %}


    {% if @type.has_constant?("RanksayCommand") && command.id == RanksayCommand.id %}
      commands = commands + services.access.ranksay_ranks.map do |rank|
        rank = services.access.ranksay(rank)

        "#{rank}say"
      end
    {% end %}

    arr << Tourmaline::CommandHandler.new(commands) do |ctx|
      next unless message = ctx.message
      next if message.date == 0 # Message is inaccessible

      message = message.as(Tourmaline::Message)

      {{handler}}.do(message, services)
    end
  end

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers(config : Config, client : Tourmaline::Client, services : Services) : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler
    bot_commands = [] of Tourmaline::BotCommand

    create_command_handlers

    client.set_my_commands(bot_commands)

    arr
  end

  # Iterate through all `HearsHandler` subclasses and initialize `Tourmaline::HearsHandler` procs for these handlers.
  macro create_hears_handlers
    {% for hears_handler in HearsHandler.all_subclasses.select { |sub_class|
                              (hears = sub_class.annotation(Hears))
                            } %}

      {{hears = hears_handler.annotation(Hears)}}

      {% if hears[:config].nil? %}
        {{warning %(Hears handler #{hears_handler} should have a configuration toggle.)}}
        append_hears_handler({{hears_handler}}, {{hears}})
      {% else %}
        if config.{{hears[:config].id}}[0]
          append_hears_handler({{hears_handler}}, {{hears}})
        else
        {% if hears[:command] %}
          arr << Tourmaline::HearsHandler.new({{hears[:pattern]}}) do |ctx|
            next unless message = ctx.message
            next if message.date == 0 # Message is inaccessible

            message = message.as(Tourmaline::Message)

            command_disabled(message, services)
          end
        {% end %}
        end
      {% end %}

    {% end %}
  end

  # Appends given `HearsHandler` to `Tourmaline::HearsHandler` array
  #
  # The given `HearsHandler` will respond to the *pattern* value of `Hears`
  macro append_hears_handler(hears_handler, hears)
    # Handler name is command's name but snake cased
    {{handler = (hears_handler.stringify.split("::").last.underscore).id}}  = {{hears_handler}}.new(config)

    arr << Tourmaline::HearsHandler.new({{hears[:pattern]}}) do |ctx|
      next unless message = ctx.message
      next if message.date == 0 # Message is inaccessible

      message = message.as(Tourmaline::Message)

      {{handler}}.do(message, services)
    end
  end

  # Intialize all "hears" handlers that inherit from `HearsHandler`
  # and are annotated with `Hears`
  def self.generate_hears_handlers(config : Config, services : Services) : Array(Tourmaline::HearsHandler)
    arr = [] of Tourmaline::HearsHandler

    create_hears_handlers

    arr
  end

  # Initializes all `CallbackHandler`
  def self.generate_callback_query_handlers(config : Config, services : Services) : Array(Tourmaline::CallbackQueryHandler)
    arr = [] of Tourmaline::CallbackQueryHandler

    {% if @type.has_constant?("StatisticsQueryHandler") %}
      return arr unless config.statistics

      handler = StatisticsQueryHandler.new(config)

      arr << Tourmaline::CallbackQueryHandler.new(/statistics-next/) do |ctx|
        next unless query = ctx.callback_query
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        handler.do(query, services)
      end
    {% end %}

    arr
  end

  # Iterate through all `UpdateHandler` subclasses and initialize `Tourmaline::UpdateHandler` procs for these handlers.
  macro create_update_handlers
    {% for update in UpdateHandler.all_subclasses.select { |sub_class|
                       (on = sub_class.annotation(On))
                     } %}

      {{update_on = update.annotation(On)}}

      {% if update_on[:config].nil? %}
        {{warning %(Update type #{update} should have a configuration toggle.)}}
        register_update_handler({{update}}, {{update_on[:update]}})
      {% else %}
        if config.{{update_on[:config].id}}
          register_update_handler({{update}}, {{update_on[:update]}})
        else
          client.on({{update_on[:update]}}) do |ctx|
            next unless message = ctx.message
            next if message.date == 0 # Message is inaccessible

            message = message.as(Tourmaline::Message)

            {% if @type.has_constant?("DocumentHandler") && update.id == DocumentHandler.id %}
              next if message.animation
            {% end %}
            media_disabled(message, {{update_on[:update]}}, services)
          end
        end
      {% end %}

    {% end %}
  end

  # Registers the given `UpdateHandler` with the bot
  #
  # The given `UpdateHandler` will respond to messages of type *update* value of `On`
  macro register_update_handler(update, on)
    {% if @type.has_constant?("ForwardHandler") && @type.has_constant?("RegularForwardHandler") && update.id == ForwardHandler.id %}
      if config.regular_forwards
        {{handler = (on.id + "_update").id.downcase}} = RegularForwardHandler.new(config)
      else
        {{handler = (on.id + "_update").id.downcase}} = ForwardHandler.new(config)
      end
    {% else %}
      {{handler = (on.id + "_update").id.downcase}}  = {{update}}.new(config)
    {% end %}

    client.on({{on}}) do |ctx|
      next unless message = ctx.message
      next if message.date == 0 # Message is inaccessible

      message = message.as(Tourmaline::Message)

      {% if @type.has_constant?("DocumentHandler") && update.id == DocumentHandler.id %}
        next if message.animation
      {% end %}
      {{handler}}.do(message, services)
    end
  end

  # Intialize all update handlers that inherit from `UpdateHandler`
  # and are annotated with `On`
  def self.generate_update_handlers(config : Config, client : Client, services : Services) : Nil
    create_update_handlers
  end

  # Queues a media_disabled system reply when the `UpdateHandler` was disabled
  def self.media_disabled(message : Tourmaline::Message, type : Tourmaline::UpdateAction, services : Services) : Nil
    return unless info = message.from

    response = Format.substitute_reply(services.replies.media_disabled, {
      "type" => type.to_s,
    })

    services.relay.send_to_user(
      ReplyParameters.new(message.message_id),
      info.id.to_i64,
      response
    )
  end

  # Queues a command_disabled system reply when the `CommandHandler` was disabled
  def self.command_disabled(message : Tourmaline::Message, services : Services) : Nil
    return unless info = message.from

    services.relay.send_to_user(ReplyParameters.new(message.message_id), info.id.to_i64, services.replies.command_disabled)
  end

  # Force-leave users whose last active time is creater than the given `Time::Span` *limit*
  def self.kick_inactive_users(limit : Time::Span, services : Services) : Nil
    services.database.inactive_users(limit).each do |user|
      user.set_left
      services.database.update_user(user)
      services.relay.reject_inactive_user_messages(user.id)

      log = Format.substitute_message(services.logs.left, {
        "id"   => user.id.to_s,
        "name" => user.formatted_name,
      })

      response = Format.substitute_reply(services.replies.inactive, {
        "time" => limit.days.to_s,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end
