RSpec.shared_context "pwhl pool" do
  include_context "pwhl teams"

  let(:admin) { create(:user) }
  let(:owner) { create(:user) }
  let(:auth_headers) { auth_headers_for(owner) }

  let(:pool) do
    create(:pool,
      league: pwhl,
      admin: admin,
      season_id: "9",
      name: "PWHL Test Pool",
    )
  end

  let!(:skater_goals_scoring) { create(:pool_scoring, :skater, :goals, value: 2, pool: pool) }
  let!(:skater_assists_scoring) { create(:pool_scoring, :skater, :assists, value: 1, pool: pool) }
  let!(:skater_shots_scoring) { create(:pool_scoring, :skater, :shots, value: 0.5, pool: pool) }
  let!(:skater_hits_scoring) { create(:pool_scoring, :skater, :hits, value: 0.5, pool: pool) }
  let!(:goalie_wins_scoring) { create(:pool_scoring, :goalie, :wins, value: 2, pool: pool) }
  let!(:goalie_saves_scoring) { create(:pool_scoring, :goalie, :saves, value: 0.1, pool: pool) }

  let(:boston) { team("1") }
  let(:ottawa) { team("5") }

  let(:skater) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "F") }
  let(:goalie) { create(:pwhl_goalie, league: pwhl, current_team: boston, position: "G") }

  let!(:pool_team) { create(:pool_team, pool: pool, owner: owner, team_name: "Test Team") }
  let!(:admin_pool_team) { create(:pool_team, pool: pool, owner: admin, team_name: "Admin Team") }

  let!(:skater_box) do
    create(:pool_box, pool: pool, name: "Forwards Box 1", league_player_ids: [skater.id])
  end

  let!(:goalie_box) do
    create(:pool_box, pool: pool, name: "Goalies Box 1", league_player_ids: [goalie.id])
  end

  let!(:inactive_box) do
    create(:pool_box, pool: pool, name: "Inactive Box", league_player_ids: [skater.id], active: false)
  end

  let!(:team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: skater,
      pool_box: skater_box,
      added_at: 1.month.ago,
    )
  end

  let!(:goalie_team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: goalie,
      pool_box: goalie_box,
      added_at: 1.month.ago,
    )
  end

  let!(:game) do
    create(:league_game, :final,
      league: pwhl,
      season_id: "9",
      start_time: Time.current,
      home_team: boston,
      away_team: ottawa,
    )
  end

  let!(:skater_stat) do
    create(:pwhl_skater_stat, :scorer,
      league: pwhl,
      league_player: skater,
      league_game: game,
      league_team: boston,
    )
  end

  let!(:goalie_stat) do
    create(:pwhl_goalie_stat, :loss,
      league: pwhl,
      league_player: goalie,
      league_game: game,
      league_team: boston,
    )
  end
end
