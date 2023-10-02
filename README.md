# Private Parlor XT
![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/Private-Parlor/Private-Parlor-XT/deploy-nightly.yml?style=for-the-badge&label=Tests)
![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/Private-Parlor/Private-Parlor-XT/deploy-nightly.yml?style=for-the-badge&label=Linux%20Nightly)
![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/Private-Parlor/Private-Parlor-XT/deploy-tag.yml?style=for-the-badge&label=Linux%20Release)

![GitHub top language](https://img.shields.io/github/languages/top/Private-Parlor/Private-Parlor-XT?style=for-the-badge&logo=crystal&labelColor=%23000000&color=%23000000)

A featureful Telegram bot to make an anonymous, private group chat on Telegram. 

Inspired by [secretlounge-ng](https://github.com/secretlounge/secretlounge-ng)

Using the [Tourmaline](https://github.com/protoncr/tourmaline) Telegram bot library.

## Notable Features
- Anonymously relay text, photos, albums, polls, videos and more to other people using the bot.
- Restrict new users from sending media by configuring the media limit period.
- Define new ranks via the configuration file with permissions to use various commands and media.
- Make tripcodes harder to crack by adding a salt to the config file.
- Add a spoiler to media before they're sent; or add a spoiler after the fact using the `/spoiler` command.
- Pin and unpin messages to the chat.
- Privately reveal your username to another user.
- Print log messages to a Telegram channel
- Kick users that have been inactive for a configurable period of time.
- Send forwarded messages as photos, videos, animations, etc. to prevent rate limiting.
- Have users automatically send every message with a tripcode using pseudonymous mode.
- Store message history in the database to reduce RAM usage.
- Localization in English, German, and Klingon.
- Persist message history longer or less than 24 hours.
- Prevent new users from joining by closing registration via the config file.
- Upvote and Downvote messages.
- Register commands with BotFather using the config file.
- Enable or disable commands and relaying of certain types of messages using the config file.
- Give users a level based on how much karma they have; user's can sign messages with their level using the `/ksign` command.
- Reduce noise and enforce original messages using the Robot 9000 auto moderator.
- *And more!*
## Installation
Compiling PrivateParlor XT requires having both `crystal` and `shards` installed.

~~~
git clone https://github.com/Private-Parlor/Private-Parlor-XT.git
cd private-parlor-xt
shards install
shards build --release
~~~
Alternatively, you can download the precompiled binaries from [Releases](https://github.com/Private-Parlor/Private-Parlor-XT/releases)

## BotFather Setup
1. Start a conversation with [BotFather](https://t.me/botfather)
2. Make a new bot with `/newbot` and answer the prompts
3. `/setprivacy`: enabled
4. `/setjoingroups`: disabled

## Usage

1. Rename `config.yaml.copy` to `config.yaml`
2. Edit config file
  - The config file should atleast contain the API Token received from botfather and a path to a SQLite database
  - Unless the database already exists, Private Parlor XT will create a new SQLite database at the given path
3. Run the `private-parlor-xt` binary

## Development

Development intructions are as follows:
- Ensure code conforms to the [Crystal API coding style](https://crystal-lang.org/reference/1.9/conventions/coding_style.html)
- Explicitly define return types and types for variables and parameters
- Document your code
- Write some specs for your code
- Lint using Ameba; remove as many warnings as possible

## Contributing

1. Fork it (<https://github.com/Private-Parlor/private-parlor-xt/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Charybdis](https://github.com/Charibdys) - creator and maintainer
