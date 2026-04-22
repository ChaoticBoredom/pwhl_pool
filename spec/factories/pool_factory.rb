FactoryBot.define do
  factory :pool do
    association :league
    association :admin, factory: :user
    name { "Test Pool" }
    pool_type { 100 }
    season_id { "2024-2025" }
  end
end
