
require "../spec_helper.cr"

module PrivateParlorXT
  class MockStatistics < Statistics
    def get_start_date : String
      "MOCKED!"
    end

    def increment_message_count(type : MessageCounts) : Nil
    end

    def increment_upvote_count : Nil
    end

    def increment_downvote_count : Nil
    end

    def increment_unoriginal_text_count : Nil
    end

    def increment_unoriginal_media_count : Nil
    end

    def get_total_messages : Hash(MessageCounts, Int32)
      {
        Statistics::MessageCounts::TotalMessages => 38,
        Statistics::MessageCounts::Albums => 2,
        Statistics::MessageCounts::Animations => 5,
        Statistics::MessageCounts::Audio => 7,
        Statistics::MessageCounts::Contacts => 0,
        Statistics::MessageCounts::Documents => 2,
        Statistics::MessageCounts::Forwards => 3,
        Statistics::MessageCounts::Locations => 0,
        Statistics::MessageCounts::Photos => 0,
        Statistics::MessageCounts::Polls => 1,
        Statistics::MessageCounts::Stickers => 0,
        Statistics::MessageCounts::Text => 10,
        Statistics::MessageCounts::Venues => 0,
        Statistics::MessageCounts::Videos => 5,
        Statistics::MessageCounts::VideoNotes => 0,
        Statistics::MessageCounts::Voice => 3,
        Statistics::MessageCounts::MessagesDaily => 8,
        Statistics::MessageCounts::MessagesYesterday => 4,
        Statistics::MessageCounts::MessagesWeekly => 16,
        Statistics::MessageCounts::MessagesYesterweek => 12,
        Statistics::MessageCounts::MessagesMonthly => 28,
        Statistics::MessageCounts::MessagesYestermonth => 10,
      }
    end

    def get_user_counts : Hash(UserCounts, Int32)
      {
        Statistics::UserCounts::TotalUsers => 30, 
        Statistics::UserCounts::TotalJoined => 19, 
        Statistics::UserCounts::TotalLeft => 11, 
        Statistics::UserCounts::TotalBlacklisted => 4, 
        Statistics::UserCounts::JoinedDaily => 4, 
        Statistics::UserCounts::JoinedYesterday => 5, 
        Statistics::UserCounts::JoinedWeekly => 17, 
        Statistics::UserCounts::JoinedYesterweek => 5, 
        Statistics::UserCounts::JoinedMonthly => 25, 
        Statistics::UserCounts::JoinedYestermonth => 5, 
        Statistics::UserCounts::LeftDaily => 2, 
        Statistics::UserCounts::LeftYesterday => 1, 
        Statistics::UserCounts::LeftWeekly => 4, 
        Statistics::UserCounts::LeftYesterweek => 5, 
        Statistics::UserCounts::LeftMonthly => 10, 
        Statistics::UserCounts::LeftYestermonth => 1,
      }
    end

    def get_karma_counts : Hash(KarmaCounts, Int32)
      {
        Statistics::KarmaCounts::TotalUpvotes => 45,
        Statistics::KarmaCounts::TotalDownvotes => 27,
        Statistics::KarmaCounts::UpvotesDaily => 10,
        Statistics::KarmaCounts::UpvotesYesterday => 3,
        Statistics::KarmaCounts::UpvotesWeekly => 14,
        Statistics::KarmaCounts::UpvotesYesterweek => 17,
        Statistics::KarmaCounts::UpvotesMonthly => 32,
        Statistics::KarmaCounts::UpvotesYestermonth => 13,
        Statistics::KarmaCounts::DownvotesDaily => 2,
        Statistics::KarmaCounts::DownvotesYesterday => 4,
        Statistics::KarmaCounts::DownvotesWeekly => 8,
        Statistics::KarmaCounts::DownvotesYesterweek => 10,
        Statistics::KarmaCounts::DownvotesMonthly => 18,
        Statistics::KarmaCounts::DownvotesYestermonth => 9,
      }
    end

    def get_karma_level_count(start_value : Int32, end_value : Int32) : Int32
      arr = [10, 16, 8, 23, 32, 44, 50, 13, -20, -70, -50, 2]

      arr.select{|x| x >= start_value && x < end_value}.size
    end

    def get_robot9000_counts : Hash(Robot9000Counts, Int32)
      {
        Statistics::Robot9000Counts::TotalUnique => 46,
        Statistics::Robot9000Counts::UniqueText => 27,
        Statistics::Robot9000Counts::UniqueMedia => 19,
        Statistics::Robot9000Counts::TotalUnoriginal => 12,
        Statistics::Robot9000Counts::UnoriginalText => 7,
        Statistics::Robot9000Counts::UnoriginalMedia => 5,
      }
    end
  end
end