require "./handlers.cr"
require "./services.cr"

module PrivateParlorXT
  def self.initialize_services : Services
    config = Config.parse_config
    localization = Localization.parse_locale(Path["./locales"], config.locale)
    database = SQLiteDatabase.new(DB.open("sqlite3://#{config.database}"))

    if config.spam_interval != 0
      spam = config.spam_handler
    else
      spam = nil
    end

    if config.database_history
      history = SQLiteHistory.new(config.message_lifespan.hours, DB.open("sqlite3://#{config.database}"))
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
    )

    initialize_handlers(client, config, services)

    services
  end

  def self.initialize_handlers(client : Tourmaline::Client, config : Config, services : Services) : Nil
    events = [] of Tourmaline::EventHandler

    events = events.concat(generate_command_handlers(config, services))

    events = events.concat(generate_hears_handlers(config, services))

    # TODO: Add Inline Queries

    events.each do |handler|
      client.register(handler)
    end

    generate_update_handlers(config, client, services)
  end

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers(config : Config, services : Services) : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler

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
        {{handler}}.do(ctx, services)
      end
    else
      arr << Tourmaline::CommandHandler.new({{command_responds_to[:command]}}) do |ctx|
        command_disabled(ctx, services)
      end
    end

    # TODO: Register command with BotFather
  {% end %}

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
        {{handler}}.do(ctx, services)
      end
    else
      arr << Tourmaline::HearsHandler.new({{command_hears[:text]}}) do |ctx|
        command_disabled(ctx, services)
      end
    end

  {% end %}

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
        {{handler}}.do(ctx, services)
      end
    else
      client.on({{update_on[:update]}}) do |ctx|
        media_disabled(ctx, {{update_on[:update]}}, services)
      end
    end

    {% end %}
  end

  def self.media_disabled(context : Tourmaline::Context, type : Tourmaline::UpdateAction, services : Services)
    return unless message = context.message
    return unless info = message.from

    response = Format.substitute_reply(services.replies.media_disabled, {
      "type" => type.to_s,
    })

    services.relay.send_to_user(message.message_id.to_i64, info.id.to_i64, response)
  end

  def self.command_disabled(context : Tourmaline::Context, services : Services)
    return unless message = context.message
    return unless info = message.from

    services.relay.send_to_user(message.message_id.to_i64, info.id.to_i64, services.replies.command_disabled)
  end
end
