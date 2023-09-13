require "./handlers.cr"

module PrivateParlorXT
  def self.initialize_handlers(
    client : Tourmaline::Client,
    config : Config,
    relay : Relay,
    access : AuthorizedRanks,
    database : Database,
    history : History,
    locale : Locale,
    spam : SpamHandler?
  ) : Nil
    events = [] of Tourmaline::EventHandler

    events = events.concat(generate_command_handlers(
      config,
      relay,
      access,
      database,
      history,
      locale,
    ))

    events = events.concat(generate_hears_handlers(config,
      relay,
      access,
      database,
      history,
      locale,
      spam,
    ))

    # TODO: Add Inline Queries

    events.each do |handler|
      client.register(handler)
    end

    generate_update_handlers(
      client,
      config,
      relay,
      access,
      database,
      history,
      locale,
      spam,
    )
  end

  # Intialize all command handlers that inherit from `CommandHandler`
  # and are annotated with `RespondsTo`
  def self.generate_command_handlers(
    config : Config,
    relay : Relay,
    access : AuthorizedRanks,
    database : Database,
    history : History,
    locale : Locale
  ) : Array(Tourmaline::CommandHandler)
    arr = [] of Tourmaline::CommandHandler

    {% for command in CommandHandler.all_subclasses.select { |sub_class|
                        (responds_to = sub_class.annotation(RespondsTo))
                      } %}

    {{command_responds_to = command.annotation(RespondsTo)}}

    if config.{{command_responds_to[:config].id}}[0]

      {% if command_responds_to[:command].is_a?(ArrayLiteral) %}
        {{handler = (command_responds_to[:command][0] + "_command").id}} = {{command}}.new(config)
      {% else %}
        {{handler = (command_responds_to[:command] + "_command").id}}  = {{command}}.new(config)
      {% end %}

      arr << Tourmaline::CommandHandler.new({{command_responds_to[:command]}}) do |ctx|
        {{handler}}.do(ctx, relay, access, database, history, locale)
      end
    end

    # TODO: Register command with BotFather
  {% end %}

    arr
  end

  # Intialize all "hears" handlers that inherit from `HearsHandler`
  # and are annotated with `Hears`
  def self.generate_hears_handlers(
    config : Config,
    relay : Relay,
    access : AuthorizedRanks,
    database : Database,
    history : History,
    locale : Locale,
    spam : SpamHandler?
  ) : Array(Tourmaline::HearsHandler)
    arr = [] of Tourmaline::HearsHandler

    {% for command in HearsHandler.all_subclasses.select { |sub_class|
                        (hears = sub_class.annotation(Hears))
                      } %}

    {{command_hears = command.annotation(Hears)}}

    if config.{{command_hears[:config].id}}[0]

      # Handler name is command's name but snake cased
      {{handler = (command.stringify.split("::").last.underscore).id}}  = {{command}}.new(config)

      arr << Tourmaline::HearsHandler.new({{command_hears[:text]}}) do |ctx|
        {{handler}}.do(ctx, relay, access, database, history, locale, spam)
      end
    end

  {% end %}

    arr
  end

  def self.generate_update_handlers(
    client : Tourmaline::Client,
    config : Config,
    relay : Relay,
    access : AuthorizedRanks,
    database : Database,
    history : History,
    locale : Locale,
    spam : SpamHandler?
  ) : Nil
    {% for update in UpdateHandler.all_subclasses.select { |sub_class|
                       (on = sub_class.annotation(On))
                     } %}

    {{update_on = update.annotation(On)}}

    if config.{{update_on[:config].id}}

      {{handler = (update_on[:update].id + "_update").id.downcase}}  = {{update}}.new(config)

      client.on({{update_on[:update]}}) do |ctx|
        {{handler}}.do(ctx, relay, access, database, history, locale, spam)
      end
    end

    {% end %}
  end
end
