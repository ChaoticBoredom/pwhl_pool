FactoryBot.define do
  factory :trade_request, class: "Trade::Request" do
    transient do
      league { raise ArgumentError, "Must pass league: explicitly to :trade_request factory" }
      decided_by { nil }
      rejected_reason { "Arbitrary Reason" }
      decided_at { Time.current }
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

    trait :approved do
      status { "pending" }

      after(:create) do |request, evaluator|
        request.decide!(
          :approved,
          decided_by: evaluator.decided_by,
          decided_at: evaluator.decided_at,
        )
      end
    end

    trait :rejected do
      status { "pending" }

      after(:create) do |request, evaluator|
        request.decide!(
          :rejected,
          decided_by: evaluator.decided_by,
          decided_at: evaluator.decided_at,
          rejected_reason: evaluator.rejected_reason,
        )
      end
    end

    trait :cancelled do
      status { "pending" }

      after(:create) do |request, evaluator|
        request.decide!(
          :cancelled,
          decided_by: evaluator.decided_by,
          decided_at: evaluator.decided_at,
        )
      end
    end
  end
end
