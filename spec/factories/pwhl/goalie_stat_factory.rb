FactoryBot.define do
  factory :pwhl_goalie_stat, class: "Pwhl::GoalieStat" do
    association :league_game
    association :league_player
    association :league_team
  end
end
