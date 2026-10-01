FactoryBot.define do
  factory :draft do
    association :pool, pool_type: :draft
    state { :pending }
    pick_order_strategy { :snake }
    current_pick_number { 0 }
    team_order { [] }
  end
end
