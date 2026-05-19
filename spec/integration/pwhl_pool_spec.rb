require "rails_helper"

RSpec.describe "PWHL Pool Integration", type: :request do
  include_context "pwhl teams"

  let(:admin) { create(:user) }
  let(:owner) { create(:user) }

  let(:pool) do
    create(:pool,
      league: pwhl,
      admin: admin,
      season_id: "9",
      name: "PWHL Test Pool",
    )
  end

  let!(:skater_goals_scoring)   { create(:pool_scoring, :skater, :goals, value: 2, pool: pool) }
  let!(:skater_assists_scoring) { create(:pool_scoring, :skater, :assists, value: 1, pool: pool) }
  let!(:skater_shots_scoring)   { create(:pool_scoring, :skater, :shots, value: 0.5, pool: pool) }
  let!(:skater_hits_scoring)    { create(:pool_scoring, :skater, :hits, value: 0.5, pool: pool) }
  let!(:goalie_wins_scoring)    { create(:pool_scoring, :goalie, :wins, value: 2, pool: pool) }
  let!(:goalie_saves_scoring)   { create(:pool_scoring, :goalie, :saves, value: 0.1, pool: pool) }

  let(:boston) { team("1") }
  let(:ottawa) { team("5") }

  let(:skater) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "F") }
  let(:goalie) { create(:pwhl_goalie, league: pwhl, current_team: boston, position: "G") }

  let!(:pool_team)       { create(:pool_team, pool: pool, owner: owner, team_name: "Test Team") }
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
      added_at: 1.month.ago
    )
  end

  let!(:goalie_team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: goalie,
      pool_box: goalie_box,
      added_at: 1.month.ago
    )
  end

  let!(:game) do
    create(:league_game, :final,
      league: pwhl,
      season_id: "9",
      start_time: Time.current,
      home_team: boston,
      away_team: ottawa
    )
  end

  let!(:skater_stat) do
    create(:pwhl_skater_stat, :scorer,
      league: pwhl,
      league_player: skater,
      league_game: game,
      league_team: boston
    )
  end

  let!(:goalie_stat) do
    create(:pwhl_goalie_stat, :loss,
      league: pwhl,
      league_player: goalie,
      league_game: game,
      league_team: boston
    )
  end

  let(:auth_headers) { auth_headers_for(owner) }

  describe "pools#show" do
    it "returns the expected response" do
      get "/api/pools/#{pool.id}", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["name"]).to eq("PWHL Test Pool")
        expect(body["id"]).to eq(pool.id)
        expect(body["pool_type"]).to eq("box_select")
        expect(body["trade_state"]).to eq("blocked")
        expect(body["games_active"]).to eq(false)

        expect(body["league"]).to eq({
          "id" => pwhl.id,
          "name" => "Professional Women's Hockey League",
          "short_name" => "PWHL",
        })

        expect(body["admin"]).to eq({
          "id" => admin.id,
          "name" => admin.name,
        })

        expect(body["pool_teams"]).to match_array([
          {
            "id" => pool_team.id,
            "team_name" => "Test Team",
            "rank" => 1,
            "total_score" => be_within(0.01).of(6.5),
            "user" => { "id" => owner.id, "name" => owner.name },
          },
          {
            "id" => admin_pool_team.id,
            "team_name" => "Admin Team",
            "rank" => 2,
            "total_score" => 0,
            "user" => { "id" => admin.id, "name" => admin.name },
          },
        ])
      end
    end
  end

  describe "pool_teams#show" do
    it "returns the expected response" do
      get "/api/pool_teams/#{pool_team.id}", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)
        expect(body["id"]).to eq(pool_team.id)
        expect(body["team_name"]).to eq("Test Team")
        expect(body["pool_id"]).to eq(pool.id)
        expect(body["total_score"]).to be_within(0.01).of(6.5)
        expect(body["trade_state"]).to eq("blocked")
        expect(body["games_active"]).to eq(false)

        expect(body["owner"]).to eq({
          "id" => owner.id,
          "name" => owner.name,
        })

        expect(body["previous_team"]).to eq([])

        skater_entry = body["current_team"].find { |p| p["league_player_id"] == skater.id }
        goalie_entry = body["current_team"].find { |p| p["league_player_id"] == goalie.id }

        zero_scores = {
          "today" => 0, "yesterday" => 0, "week_to_date" => 0,
          "month_to_date" => 0, "season_to_date" => 0
        }

        skater_scores = {
          "today" => be_within(0.01).of(4.5),
          "yesterday" => 0,
          "week_to_date" => be_within(0.01).of(4.5),
          "month_to_date" => be_within(0.01).of(4.5),
          "season_to_date" => be_within(0.01).of(4.5),
        }

        goalie_scores = {
          "today" => be_within(0.01).of(2.0),
          "yesterday" => 0,
          "week_to_date" => be_within(0.01).of(2.0),
          "month_to_date" => be_within(0.01).of(2.0),
          "season_to_date" => be_within(0.01).of(2.0),
        }

        [
          [skater_entry, team_player, skater, skater_box, 4.5, skater_scores],
          [goalie_entry, goalie_team_player, goalie, goalie_box, 2.0, goalie_scores],
        ].each do |entry, tp, player, box, pool_score, scores|
          expect(entry["id"]).to eq(tp.id), "#{player.name} team_player id mismatch"
          expect(entry["league_player_id"]).to eq(player.id), "#{player.name} league_player_id mismatch"
          expect(entry["name"]).to eq(player.name), "#{player.name} name mismatch"
          expect(entry["current_team_short_code"]).to eq("BOS"), "#{player.name} team mismatch"
          expect(entry["added_at"]).to eq(tp.added_at.iso8601(3)), "#{player.name} added_at mismatch"
          expect(entry["pool_box_position"]).to eq(box.position), "#{player.name} box position mismatch"
          expect(entry["scores"]["pool_score"]).to be_within(0.01).of(pool_score),
            "#{player.name} pool_score mismatch"
          expect(entry["scores"]["scores"]).to match(scores),
            "#{player.name} scores mismatch"
          expect(entry["scores"]["clipped_scores"]).to match(scores),
            "#{player.name} clipped_scores mismatch"
          expect(entry["games"]).to eq({
            "upcoming" => {},
            "today" => { "id" => game.id },
          }), "#{player.name} games mismatch"
        end
      end
    end
  end

  describe "players/:id/team_player (skater)" do
    it "returns the expected response" do
      get "/api/players/#{team_player.id}/team_player", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)
        expect(body["id"]).to eq(skater.id)
        expect(body["name"]).to eq(skater.name)
        expect(body["current_team_id"]).to eq(skater.current_team_id)
        expect(body["current_team_short_code"]).to eq("BOS")

        zero_skater_window = {
          "goals" => 0, "assists" => 0, "penalty_minutes" => 0,
          "shots" => 0, "hits" => 0, "time_on_ice" => 0,
          "plus_minus" => 0, "power_play_goals" => 0,
          "short_handed_goals" => 0, "shots_blocked" => 0,
          "faceoffs_taken" => 0, "faceoffs_won" => 0,
          "game_winning_goals" => 0
        }

        season_skater_window = {
          "goals" => 1, "assists" => 1, "penalty_minutes" => 0,
          "shots" => 3, "hits" => 0, "time_on_ice" => 900,
          "plus_minus" => 2, "power_play_goals" => 0,
          "short_handed_goals" => 0, "shots_blocked" => 0,
          "faceoffs_taken" => 0, "faceoffs_won" => 0,
          "game_winning_goals" => 0
        }

        [
          ["today", season_skater_window],
          ["yesterday", zero_skater_window],
          ["week_to_date", season_skater_window],
          ["month_to_date", season_skater_window],
          ["season_to_date", season_skater_window],
        ].each do |window, expected|
          expect(body["raw_stats"]["scores"][window]).to eq(expected),
            "raw_stats scores #{window} mismatch"
          expect(body["raw_stats"]["clipped_scores"][window]).to eq(expected),
            "raw_stats clipped_scores #{window} mismatch"
        end

        zero_expanded_skater_window = {
          "goals" => 0.0, "assists" => 0.0, "penalty_minutes" => 0.0,
          "shots" => 0.0, "hits" => 0.0, "time_on_ice" => 0.0,
          "plus_minus" => 0.0, "power_play_goals" => 0.0,
          "short_handed_goals" => 0.0, "shots_blocked" => 0.0,
          "faceoffs_taken" => 0.0, "faceoffs_won" => 0.0,
          "game_winning_goals" => 0.0
        }

        season_expanded_skater_window = {
          "goals" => 2.0, "assists" => 1.0, "penalty_minutes" => 0.0,
          "shots" => 1.5, "hits" => 0.0, "time_on_ice" => 0.0,
          "plus_minus" => 0.0, "power_play_goals" => 0.0,
          "short_handed_goals" => 0.0, "shots_blocked" => 0.0,
          "faceoffs_taken" => 0.0, "faceoffs_won" => 0.0,
          "game_winning_goals" => 0.0
        }

        [
          ["today", season_expanded_skater_window],
          ["yesterday", zero_expanded_skater_window],
          ["week_to_date", season_expanded_skater_window],
          ["month_to_date", season_expanded_skater_window],
          ["season_to_date", season_expanded_skater_window],
        ].each do |window, expected|
          expect(body["expanded_pool_scores"]["scores"][window]).to eq(expected),
            "expanded_pool_scores scores #{window} mismatch"
          expect(body["expanded_pool_scores"]["clipped_scores"][window]).to eq(expected),
            "expanded_pool_scores clipped_scores #{window} mismatch"
        end

        [
          ["today", be_within(0.01).of(4.5)],
          ["yesterday", eq(0)],
          ["week_to_date", be_within(0.01).of(4.5)],
          ["month_to_date", be_within(0.01).of(4.5)],
          ["season_to_date", be_within(0.01).of(4.5)],
        ].each do |window, matcher|
          expect(body["pool_scores"]["scores"][window]).to matcher,
            "pool_scores scores #{window} mismatch"
          expect(body["pool_scores"]["clipped_scores"][window]).to matcher,
            "pool_scores clipped_scores #{window} mismatch"
        end

        expect(body["labels"]).to eq({
          "goals" => "Goals", "assists" => "Assists", "shots" => "Shots",
          "hits" => "Hits", "saves" => "Saves", "shutout" => "Shutouts",
          "win" => "Wins", "penalty_minutes" => "PIM",
          "power_play_goals" => "PPG", "short_handed_goals" => "SHG",
          "faceoffs_won" => "Faceoffs Won", "faceoffs_taken" => "Faceoffs",
          "time_on_ice" => "TOI", "plus_minus" => "+/-",
          "shots_against" => "SA", "goals_against" => "GA",
          "game_started" => "Games Started", "game_winning_goals" => "GWG",
          "shots_blocked" => "Blocked"
        })
      end
    end
  end

  describe "players/:id/team_player (goalie)" do
    it "returns the expected response" do
      get "/api/players/#{goalie_team_player.id}/team_player", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)
        expect(body["id"]).to eq(goalie.id)
        expect(body["name"]).to eq(goalie.name)
        expect(body["current_team_id"]).to eq(goalie.current_team_id)
        expect(body["current_team_short_code"]).to eq("BOS")

        zero_goalie_window = {
          "goals" => 0, "assists" => 0, "goals_against" => 0,
          "shots_against" => 0, "penalty_minutes" => 0, "win" => 0,
          "shutout" => 0, "saves" => 0, "time_on_ice" => 0,
          "game_started" => 0
        }

        season_goalie_window = {
          "goals" => 0, "assists" => 0, "goals_against" => 5,
          "shots_against" => 25, "penalty_minutes" => 0, "win" => 0,
          "shutout" => 0, "saves" => 20, "time_on_ice" => 3600,
          "game_started" => 1
        }

        [
          ["today", season_goalie_window],
          ["yesterday", zero_goalie_window],
          ["week_to_date", season_goalie_window],
          ["month_to_date", season_goalie_window],
          ["season_to_date", season_goalie_window],
        ].each do |window, expected|
          expect(body["raw_stats"]["scores"][window]).to eq(expected),
            "raw_stats scores #{window} mismatch"
          expect(body["raw_stats"]["clipped_scores"][window]).to eq(expected),
            "raw_stats clipped_scores #{window} mismatch"
        end

        zero_expanded_goalie_window = {
          "goals" => 0.0, "assists" => 0.0, "goals_against" => 0.0,
          "shots_against" => 0.0, "penalty_minutes" => 0.0, "win" => 0.0,
          "shutout" => 0.0, "saves" => 0.0, "time_on_ice" => 0.0,
          "game_started" => 0.0
        }

        season_expanded_goalie_window = {
          "goals" => 0.0, "assists" => 0.0, "goals_against" => 0.0,
          "shots_against" => 0.0, "penalty_minutes" => 0.0, "win" => 0.0,
          "shutout" => 0.0, "saves" => be_within(0.01).of(2.0),
          "time_on_ice" => 0.0, "game_started" => 0.0
        }

        [
          ["today", season_expanded_goalie_window],
          ["yesterday", zero_expanded_goalie_window],
          ["week_to_date", season_expanded_goalie_window],
          ["month_to_date", season_expanded_goalie_window],
          ["season_to_date", season_expanded_goalie_window],
        ].each do |window, expected|
          expect(body["expanded_pool_scores"]["scores"][window]).to match(expected),
            "expanded_pool_scores scores #{window} mismatch"
          expect(body["expanded_pool_scores"]["clipped_scores"][window]).to match(expected),
            "expanded_pool_scores clipped_scores #{window} mismatch"
        end

        [
          ["today", be_within(0.01).of(2.0)],
          ["yesterday", eq(0)],
          ["week_to_date", be_within(0.01).of(2.0)],
          ["month_to_date", be_within(0.01).of(2.0)],
          ["season_to_date", be_within(0.01).of(2.0)],
        ].each do |window, matcher|
          expect(body["pool_scores"]["scores"][window]).to matcher,
            "pool_scores scores #{window} mismatch"
          expect(body["pool_scores"]["clipped_scores"][window]).to matcher,
            "pool_scores clipped_scores #{window} mismatch"
        end

        expect(body["labels"]).to eq({
          "goals" => "Goals", "assists" => "Assists", "shots" => "Shots",
          "hits" => "Hits", "saves" => "Saves", "shutout" => "Shutouts",
          "win" => "Wins", "penalty_minutes" => "PIM",
          "power_play_goals" => "PPG", "short_handed_goals" => "SHG",
          "faceoffs_won" => "Faceoffs Won", "faceoffs_taken" => "Faceoffs",
          "time_on_ice" => "TOI", "plus_minus" => "+/-",
          "shots_against" => "SA", "goals_against" => "GA",
          "game_started" => "Games Started", "game_winning_goals" => "GWG",
          "shots_blocked" => "Blocked"
        })
      end
    end
  end

  describe "scorings#index" do
    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["skaters"].map { |s| s["field_name"] }).to match_array(%w[
          goals assists shots hits
        ])

        expect(body["goalies"].map { |s| s["field_name"] }).to match_array(%w[
          win saves
        ])

        [
          ["skaters", "goals", 2.0],
          ["skaters", "assists", 1.0],
          ["skaters", "shots", 0.5],
          ["skaters", "hits", 0.5],
          ["goalies", "win", 2.0],
          ["goalies", "saves", 0.1],
        ].each do |roster_type, field, value|
          entry = body[roster_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(value),
            "#{roster_type} #{field} value mismatch"
        end
      end
    end
  end

  describe "pool_boxes#index" do
    let(:other_skater) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "F") }
    let(:other_goalie) { create(:pwhl_goalie, league: pwhl, current_team: ottawa, position: "G") }
    let!(:skater_box) do
      create(:pool_box, pool: pool, name: "Forwards Box 1", league_player_ids: [skater.id, other_skater.id])
    end

    let!(:goalie_box) do
      create(:pool_box, pool: pool, name: "Goalies Box 1", league_player_ids: [goalie.id, other_goalie.id])
    end

    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_boxes", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200), "expected 200"
        expect(body["using_reference_season"]).to eq(false), "using_reference_season mismatch"

        box_names = body["boxes"].map { |b| b["name"] }
        expect(box_names).to match_array(["Forwards Box 1", "Goalies Box 1"]), "box names mismatch"

        skater_json = body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"]
          .find { |p| p["id"] == skater.id }
        goalie_json = body["boxes"].find { |b| b["name"] == "Goalies Box 1" }["players"]
          .find { |p| p["id"] == goalie.id }

        other_skater_json = body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"]
          .find { |p| p["id"] == other_skater.id }
        other_goalie_json = body["boxes"].find { |b| b["name"] == "Goalies Box 1" }["players"]
          .find { |p| p["id"] == other_goalie.id }


        expect(skater_json).not_to be_nil, "skater missing from Forwards Box 1"
        expect(goalie_json).not_to be_nil, "goalie missing from Goalies Box 1"
        expect(other_skater_json).not_to be_nil, "other_skater missing from Forwards Box 1"
        expect(other_goalie_json).not_to be_nil, "other_goalie missing from Goalies Box 1"

        expect(skater_json["selected"]).to eq(true), "skater should be selected (on pool_team)"
        expect(goalie_json["selected"]).to eq(true), "goalie should be selected (on pool_team)"
        expect(other_skater_json["selected"]).to eq(false), "other_skater should be not be selected (not on pool_team)"
        expect(other_goalie_json["selected"]).to eq(false), "other_goalie should be not be selected (not on pool_team)"

        expect(skater_json["scores"]["today"]).to be_within(0.01).of(4.5),
          "skater today score mismatch"
        expect(skater_json["scores"]["season_to_date"]).to be_within(0.01).of(4.5),
          "skater season_to_date score mismatch"

        expect(goalie_json["scores"]["today"]).to be_within(0.01).of(2.0),
          "goalie today score mismatch"
        expect(goalie_json["scores"]["season_to_date"]).to be_within(0.01).of(2.0),
          "goalie season_to_date score mismatch"

        expect(other_skater_json["scores"]["today"]).to eq(0), "other_skater today score mismatch"
        expect(other_skater_json["scores"]["season_to_date"]).to eq(0), "other_skater season_to_date score mismatch"

        expect(other_goalie_json["scores"]["today"]).to eq(0), "other_goalie today score mismatch"
        expect(other_goalie_json["scores"]["season_to_date"]).to eq(0), "other_goalie season_to_date score mismatch"
      end
    end
  end

  describe "pool_boxes#generate" do
    it "returns the expected response" do
      post "/api/pools/#{pool.id}/pool_boxes/generate",
        headers: auth_headers.merge(
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        ),
        params: {
          teams: ["BOS"],
          scope: :per_team,
          excluded_player_ids: [],
          boxes: [
            { name: "Forwards Box 1", position: "F", rookie: false, rank: 1, count: 1 },
            { name: "Goalies Box 1", position: "G", rookie: nil, rank: 1, count: 1 },
          ],
        }.to_json

      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["boxes"].map { |b| b["name"] }).to match_array([
          "Forwards Box 1",
          "Goalies Box 1",
        ])

        [
          ["Forwards Box 1", skater.id, be_within(0.01).of(4.5)],
          ["Goalies Box 1", goalie.id, be_within(0.01).of(2.0)],
        ].each do |box_name, player_id, score_matcher|
          box = body["boxes"].find { |b| b["name"] == box_name }
          expect(box["players"]).not_to be_empty, "#{box_name} had no players"
          expect(box["players"].first["id"]).to eq(player_id),
            "#{box_name} first player id mismatch"
          expect(box["players"].first["score"]).to score_matcher,
            "#{box_name} first player score mismatch"
        end
      end
    end
  end
end
