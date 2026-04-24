FactoryBot.define do
  factory :pool_team_player, class: "Pool::TeamPlayer" do
    association :pool_team
    association :league_player
    added_at { Time.current }
  end
end
