FactoryBot.define do
  factory :pool_team_player, class: "Pool::TeamPlayer" do
    transient do
      pool_team { raise ArgumentError, "Must pass pool_team: explicitly to :pool_team_player factory" }
    end

    association :league_player
    added_at { Time.current }

    after(:build) do |tp, evaluator|
      tp.pool_team = evaluator.pool_team
      tp.pool = evaluator.pool_team.pool || build(:pool)
      tp.pool_box ||= create(:pool_box, pool: evaluator.pool_team.pool)
    end
  end
end
