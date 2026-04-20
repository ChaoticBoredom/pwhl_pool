FactoryBot.define do
  factory :pwhl_skater_stat, class: "Pwhl::SkaterStat" do
    association :league_game
    association :league_player
    association :league_team
  end
end
