FactoryBot.define do
  factory :trade_request, class: "Trade::Request" do
    transient do
      league { raise ArgumentError, "Must pass league: explicitly to :trade_request factory" }
    end

    association :pool_team
    association :league_player
    association :requested_by, factory: :user
    association :pool_box

    requested_at { 5.hours.ago }

    trait :add do
      action { "add" }
    end

    trait :drop do
      action { "drop" }
    end

    trait :pending do
      status { "pending" }
    end
  end
end
