require "../spec_helper.cr"

module PrivateParlorXT

  # NOTE: Can't test most of the 'send_*' functions as these work directly with the Telegram API

  describe Relay do
    describe "#reject_blacklisted_messages" do
      it "removes messages sent by and addressed to the given user" do
        services = create_services()

        # 10 messages in the queue; 5 should be removed
        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 9000_i64,
          receivers: [10000_i64, 11000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 10000_i64,
          receivers: [10000_i64, 9000_i64, 11000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 11000_i64,
          receivers: [9000_i64, 10000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 10000_i64,
          receivers: [10000_i64, 9000_i64, 11000_i64]
        ))

        services.relay.reject_blacklisted_messages(9000)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(5))
        messages.each do |message|
          message.sender.should_not(eq(9000))
          message.receiver.should_not(eq(9000))
        end
      end
    end

    describe "#reject_inactive_user_messages" do
      it "removes messages addressed to the given user" do
        services = create_services()

        # 10 messages in the queue; 3 should be removed
        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 9000_i64,
          receivers: [10000_i64, 11000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 10000_i64,
          receivers: [10000_i64, 9000_i64, 11000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 11000_i64,
          receivers: [9000_i64, 10000_i64]
        ))

        services.relay.send_text(RelayParameters.new(
          original_message: 300_i64,
          sender: 10000_i64,
          receivers: [10000_i64, 9000_i64, 11000_i64]
        ))

        services.relay.reject_inactive_user_messages(9000)

        messages = services.relay.as(MockRelay).empty_queue

        messages.size.should(eq(7))
        messages.each do |message|
          message.receiver.should_not(eq(9000))
        end
      end
    end

    describe "#cache_message" do 
      it "caches a Telegram message ID" do
        services = create_services()

        queued_message = QueuedMessage.new(
          origin_msid: 11,
          sender: 9000,
          receiver: 10000,
          reply_to: nil,
          function: ->(_receiver : UserID, _message : ReplyParameters?) { true }
        )

        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        message = Tourmaline::Message.new(
          message_id: 12,
          date: Time.utc,
          chat: Tourmaline::Chat.new(bot_user.id, "private"),
          from: bot_user,
        )

        services.history.new_message(sender_id: 9000, origin: 11)

        services.relay.cache_message(message, queued_message, services)

        receivers = services.history.get_all_receivers(11)

        receivers[10000].should(eq(12))
      end

      it "caches an array of Telegram message ID" do
        services = create_services()

        queued_message = QueuedMessage.new(
            origin_msid: [11_i64, 12_i64, 13_i64],
            sender: 9000_i64,
            receiver: 10000_i64,
            reply_to: nil,
            function: ->(_receiver : UserID, _message : ReplyParameters?) { true }
          )

        bot_user = Tourmaline::User.new(12345678, true, "Spec")

        messages = [
          Tourmaline::Message.new(
            message_id: 14,
            date: Time.utc,
            chat: Tourmaline::Chat.new(bot_user.id, "private"),
            from: bot_user,
          ),
          Tourmaline::Message.new(
            message_id: 15,
            date: Time.utc,
            chat: Tourmaline::Chat.new(bot_user.id, "private"),
            from: bot_user,
          ),
          Tourmaline::Message.new(
            message_id: 16,
            date: Time.utc,
            chat: Tourmaline::Chat.new(bot_user.id, "private"),
            from: bot_user,
          ),
        ]

        services.history.new_message(sender_id: 9000, origin: 11)
        services.history.new_message(sender_id: 9000, origin: 12)
        services.history.new_message(sender_id: 9000, origin: 13)

        services.relay.cache_message(messages, queued_message, services)

        message_one_receivers = services.history.get_all_receivers(11)
        message_two_receivers = services.history.get_all_receivers(12)
        message_three_receivers = services.history.get_all_receivers(13)

        message_one_receivers[10000].should(eq(14))
        message_two_receivers[10000].should(eq(15))
        message_three_receivers[10000].should(eq(16))
      end
    end
  end
end