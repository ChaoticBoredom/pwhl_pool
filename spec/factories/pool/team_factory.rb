FactoryBot.define do
  factory :pool_team, class: "Pool::Team" do
    team_name { Faker::Team.name }
    association :pool
    association :owner, factory: :user
  end
end
