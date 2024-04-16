require "./command_handler.cr"
require "./hears_handler.cr"
require "./update_handler.cr"
require "./services.cr"
require "tasker"

module PrivateParlorXT
  def self.initialize_services : Services
    config = Config.parse_config
    localization = Localization.parse_locale(Path["./locales"], config.locale)

    connection = DB.open("sqlite3://#{config.database}")

    database = SQLiteDatabase.new(connection)

    if config.spam_interval != 0
      spam = config.spam_handler
    else
      spam = nil
    end

    if config.toggle_r9k_media || config.toggle_r9k_text
      robot9000 = SQLiteRobot9000.new(
        connection,
        config.valid_codepoints,
        config.toggle_r9k_text,
        config.toggle_r9k_media,
        config.toggle_r9k_forwards,
        config.r9k_warn,
        config.r9k_cooldown,
      )
    else
      robot9000 = nil
    end

    if config.karma_economy != nil
      karma_economy = config.karma_economy
    end

    if config.statistics != nil
      stats = SQLiteStatistics.new(connection)
    end

    if config.database_history
      history = SQLiteHistory.new(config.message_lifespan.hours, connection)
    else
      history = CachedHistory.new(config.message_lifespan.hours)
    end

    access = AuthorizedRanks.new(config.ranks)

    client = Client.new(config.token)
    client.default_parse_mode = Tourmaline::ParseMode::MarkdownV2

    relay = Relay.new(config.log_channel, client)

    services = Services.new(
      HandlerConfig.new(config),
      localization.locale,
      localization.replies,
      localization.logs,
      localization.command_descriptions,
      database,
      history,
      access,
      relay,
      spam,
      robot9000,
      karma_economy,
      stats
    )

    initialize_tasks(config, services)

    initialize_handlers(client, config, services)

    services
  end

  def self.initialize_tasks(config : Config, services : Services)
    Tasker.every(15.minutes) {
      services.database.expire_warnings(config.warn_lifespan.hours)
    }

    if config.message_lifespan > 0
      Tasker.every(config.message_lifespan.hours * (1/4)) {
        services.history.expire
      }
    end

    if spam = services.spam
      Tasker.every(config.spam_interval.seconds) {
        spam.expire
      }
    end

    if config.inactivity_limit > 0
      Tasker.every(6.hours) {
        kick_inactive_users(config.inactivity_limit.days, services)
      }
    end
  end

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

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers(config : Config, client : Tourmaline::Client, services : Services) : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler
    bot_commands = [] of Tourmaline::BotCommand

    {% for command in CommandHandler.all_subclasses.select { |sub_class|
                        (responds_to = sub_class.annotation(RespondsTo))
                      } %}

    {{command_responds_to = command.annotation(RespondsTo)}}

    if config.{{command_responds_to[:config].id}}[0]
      commands = [] of String

      {% if command_responds_to[:command].is_a?(ArrayLiteral) %}
        commands = commands + {{command_responds_to[:command]}}
        {{handler = (command_responds_to[:command][0] + "_command").id}} = {{command}}.new(config)
      {% else %}
        commands << {{command_responds_to[:command]}}
        {{handler = (command_responds_to[:command] + "_command").id}}  = {{command}}.new(config)
      {% end %}

      {% if command == RanksayCommand %}
        commands = commands + services.access.ranksay_ranks.map {|rank| "#{rank.downcase}say"}
      {% end %}

      arr << Tourmaline::CommandHandler.new(commands) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        {{handler}}.do(message, services)
      end
    else
      arr << Tourmaline::CommandHandler.new({{command_responds_to[:command]}}) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        command_disabled(message, services)
      end
    end

    if config.{{command_responds_to[:config].id}}[1]
      bot_commands << Tourmaline::BotCommand.new(
        {% if command_responds_to[:command].is_a?(ArrayLiteral) %}
          {{command_responds_to[:command][0]}},
          services.command_descriptions.{{command_responds_to[:command][0].id}}
        {% else %}
          {{command_responds_to[:command]}},
          services.command_descriptions.{{command_responds_to[:command].id}}
        {% end %}
      )
    end
  {% end %}

    client.set_my_commands(bot_commands)

    arr
  end

  # Intialize all "hears" handlers that inherit from `HearsHandler`
  # and are annotated with `Hears`
  def self.generate_hears_handlers(config : Config, services : Services) : Array(Tourmaline::HearsHandler)
    arr = [] of Tourmaline::HearsHandler

    {% for command in HearsHandler.all_subclasses.select { |sub_class|
                        (hears = sub_class.annotation(Hears))
                      } %}

    {{command_hears = command.annotation(Hears)}}

    if config.{{command_hears[:config].id}}[0]

      # Handler name is command's name but snake cased
      {{handler = (command.stringify.split("::").last.underscore).id}}  = {{command}}.new(config)

      arr << Tourmaline::HearsHandler.new({{command_hears[:text]}}) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        {{handler}}.do(message, services)
      end
    else
      arr << Tourmaline::HearsHandler.new({{command_hears[:text]}}) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        command_disabled(message, services)
      end
    end

  {% end %}

    arr
  end

  def self.generate_callback_query_handlers(config : Config, services : Services) : Array(Tourmaline::CallbackQueryHandler)
    arr = [] of Tourmaline::CallbackQueryHandler

    return arr unless config.statistics

    handler = StatisticsQueryHandler.new(config)

    arr << Tourmaline::CallbackQueryHandler.new(/statistics-next/) do |ctx|
      next unless query = ctx.callback_query
      next unless message = ctx.message
      next if message.date == 0 # Message is inaccessible

      handler.do(query, services)
    end

    arr
  end

  def self.generate_update_handlers(config : Config, client : Client, services : Services) : Nil
    {% for update in UpdateHandler.all_subclasses.select { |sub_class|
                       (on = sub_class.annotation(On))
                     } %}

    {{update_on = update.annotation(On)}}

    if config.{{update_on[:config].id}}
      {% if update == ForwardHandler %}
        if config.regular_forwards
          {{handler = (update_on[:update].id + "_update").id.downcase}} = RegularForwardHandler.new(config)
        else
          {{handler = (update_on[:update].id + "_update").id.downcase}} = ForwardHandler.new(config)
        end
      {% else %}
        {{handler = (update_on[:update].id + "_update").id.downcase}}  = {{update}}.new(config)
      {% end %}

      client.on({{update_on[:update]}}) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        {% if update == DocumentHandler %}
          next if message.animation
        {% end %}
        {{handler}}.do(message, services)
      end
    else
      client.on({{update_on[:update]}}) do |ctx|
        next unless message = ctx.message
        next if message.date == 0 # Message is inaccessible

        message = message.as(Tourmaline::Message)

        {% if update == DocumentHandler %}
          next if message.animation
        {% end %}
        media_disabled(message, {{update_on[:update]}}, services)
      end
    end

    {% end %}
  end

  def self.media_disabled(message : Tourmaline::Message, type : Tourmaline::UpdateAction, services : Services)
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

  def self.command_disabled(message : Tourmaline::Message, services : Services)
    return unless info = message.from

    services.relay.send_to_user(ReplyParameters.new(message.message_id), info.id.to_i64, services.replies.command_disabled)
  end

  def self.kick_inactive_users(limit : Time::Span, services : Services)
    services.database.get_inactive_users(limit).each do |user|
      user.set_left
      services.database.update_user(user)
      services.relay.reject_inactive_user_messages(user.id)

      log = Format.substitute_message(services.logs.left, {
        "id"   => user.id.to_s,
        "name" => user.get_formatted_name,
      })

      response = Format.substitute_reply(services.replies.inactive, {
        "time" => limit.days.to_s,
      })

      services.relay.log_output(log)

      services.relay.send_to_user(nil, user.id, response)
    end
  end
end
