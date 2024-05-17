
require "../spec_helper.cr"

module PrivateParlorXT
  class MockStatistics < Statistics
    def start_date : String
      "MOCKED!"
    end

    def increment_messages(type : Messages) : Nil
    end

    def increment_upvotes : Nil
    end

    def increment_downvotes : Nil
    end

    def increment_unoriginal_text : Nil
    end

    def increment_unoriginal_media : Nil
    end

    def message_counts : Hash(Messages, Int32)
      {
        Statistics::Messages::TotalMessages => 38,
        Statistics::Messages::Albums => 2,
        Statistics::Messages::Animations => 5,
        Statistics::Messages::Audio => 7,
        Statistics::Messages::Contacts => 0,
        Statistics::Messages::Documents => 2,
        Statistics::Messages::Forwards => 3,
        Statistics::Messages::Locations => 0,
        Statistics::Messages::Photos => 0,
        Statistics::Messages::Polls => 1,
        Statistics::Messages::Stickers => 0,
        Statistics::Messages::Text => 10,
        Statistics::Messages::Venues => 0,
        Statistics::Messages::Videos => 5,
        Statistics::Messages::VideoNotes => 0,
        Statistics::Messages::Voice => 3,
        Statistics::Messages::MessagesDaily => 8,
        Statistics::Messages::MessagesYesterday => 4,
        Statistics::Messages::MessagesWeekly => 16,
        Statistics::Messages::MessagesYesterweek => 12,
        Statistics::Messages::MessagesMonthly => 28,
        Statistics::Messages::MessagesYestermonth => 10,
      }
    end

    def user_counts : Hash(Users, Int32)
      {
        Statistics::Users::TotalUsers => 30, 
        Statistics::Users::TotalJoined => 19, 
        Statistics::Users::TotalLeft => 11, 
        Statistics::Users::TotalBlacklisted => 4, 
        Statistics::Users::JoinedDaily => 4, 
        Statistics::Users::JoinedYesterday => 5, 
        Statistics::Users::JoinedWeekly => 17, 
        Statistics::Users::JoinedYesterweek => 5, 
        Statistics::Users::JoinedMonthly => 25, 
        Statistics::Users::JoinedYestermonth => 5, 
        Statistics::Users::LeftDaily => 2, 
        Statistics::Users::LeftYesterday => 1, 
        Statistics::Users::LeftWeekly => 4, 
        Statistics::Users::LeftYesterweek => 5, 
        Statistics::Users::LeftMonthly => 10, 
        Statistics::Users::LeftYestermonth => 1,
      }
    end

    def karma_counts : Hash(Karma, Int32)
      {
        Statistics::Karma::TotalUpvotes => 45,
        Statistics::Karma::TotalDownvotes => 27,
        Statistics::Karma::UpvotesDaily => 10,
        Statistics::Karma::UpvotesYesterday => 3,
        Statistics::Karma::UpvotesWeekly => 14,
        Statistics::Karma::UpvotesYesterweek => 17,
        Statistics::Karma::UpvotesMonthly => 32,
        Statistics::Karma::UpvotesYestermonth => 13,
        Statistics::Karma::DownvotesDaily => 2,
        Statistics::Karma::DownvotesYesterday => 4,
        Statistics::Karma::DownvotesWeekly => 8,
        Statistics::Karma::DownvotesYesterweek => 10,
        Statistics::Karma::DownvotesMonthly => 18,
        Statistics::Karma::DownvotesYestermonth => 9,
      }
    end

    def karma_level_count(start_value : Int32, end_value : Int32) : Int32
      arr = [10, 16, 8, 23, 32, 44, 50, 13, -20, -70, -50, 2]

      arr.select{|x| x >= start_value && x < end_value}.size
    end

    def robot9000_counts : Hash(Robot9000, Int32)
      {
        Statistics::Robot9000::TotalUnique => 46,
        Statistics::Robot9000::UniqueText => 27,
        Statistics::Robot9000::UniqueMedia => 19,
        Statistics::Robot9000::TotalUnoriginal => 12,
        Statistics::Robot9000::UnoriginalText => 7,
        Statistics::Robot9000::UnoriginalMedia => 5,
      }
    end
  end
end