module PrivateParlorXT
  # The `Int64` ID of a user
  alias UserID = Int64

  # The ID of a Telegram message, stored as a `Int64`
  alias MessageID = Int64

  # Simple alias for `Tourmaline::ReplyParameters`
  alias ReplyParameters = Tourmaline::ReplyParameters

  # The possible types for one element in an album/media group
  alias AlbumMedia = Tourmaline::InputMediaPhoto | Tourmaline::InputMediaVideo | Tourmaline::InputMediaAudio | Tourmaline::InputMediaDocument

  # The proc associated with a `QueuedMessage`
  # 
  # A `MessageProc` can return the following types:
  #   - `Tourmaline::Message`: Functions that send text messages, photos, GIFs, and similar items will return a single `Tourmaline::Message`
  #   - `Array(Tourmaline::Message)`: Functions that send albums/media groups will return an array of the the sent `Tourmaline::Message`
  #   - `Bool`: Functions that delete, pin, or edit messages will return a `Bool`, where `true` represents a success and `false` represents a failure. 
  #     A `Bool` result is currently not useful to the bot.
  alias MessageProc = Proc(UserID, ReplyParameters?, Tourmaline::Message) |
                      Proc(UserID, ReplyParameters?, Array(Tourmaline::Message)) |
                      Proc(UserID, ReplyParameters?, Bool)
end
