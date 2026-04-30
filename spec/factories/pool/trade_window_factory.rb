FactoryBot.define do
  factory :pool_trade_window, class: "Pool::TradeWindow" do
    association :pool
    open_window { 5.days.ago..5.days.from_now }

    trait :future do
      open_window { 5.days.from_now..10.days.from_now }
    end

    trait :past do
      open_window { 10.days.ago..5.days.ago }
    end
  end
end
