require "rails_helper"

RSpec.describe "players", type: :request do
  include_context "pwhl pool"

  let(:stat_labels) do
    {
      "goals" => "Goals", "assists" => "Assists", "shots" => "Shots",
      "hits" => "Hits", "saves" => "Saves", "shutout" => "Shutouts",
      "win" => "Wins", "penalty_minutes" => "PIM",
      "power_play_goals" => "PPG", "short_handed_goals" => "SHG",
      "faceoffs_won" => "Faceoffs Won", "faceoffs_taken" => "Faceoffs",
      "time_on_ice" => "TOI", "plus_minus" => "+/-",
      "shots_against" => "SA", "goals_against" => "GA",
      "game_started" => "Games Started", "game_winning_goals" => "GWG",
      "shots_blocked" => "Blocked"
    }
  end

  describe "players/:id (skater)" do
    it "returns the expected response" do
      get "/api/players/#{skater.id}",
        params: { pool_id: pool.id },
        headers: auth_headers
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
        end

        expect(body["raw_stats"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped_scores"

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
        end

        expect(body["expanded_pool_scores"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped expanded scores"

        [
          ["today", be_within(0.01).of(4.5)],
          ["yesterday", eq(0)],
          ["week_to_date", be_within(0.01).of(4.5)],
          ["month_to_date", be_within(0.01).of(4.5)],
          ["season_to_date", be_within(0.01).of(4.5)],
        ].each do |window, matcher|
          expect(body["pool_scores"]["scores"][window]).to matcher,
            "pool_scores scores #{window} mismatch"
        end

        expect(body["pool_scores"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped pool_scores"

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

  describe "players/:id (goalie)" do
    it "returns the expected response" do
      get "/api/players/#{goalie.id}",
        params: { pool_id: pool.id },
        headers: auth_headers
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
        end

        expect(body["raw_stats"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped_scores"

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
        end

        expect(body["expanded_pool_scores"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped expanded scores"

        [
          ["today", be_within(0.01).of(2.0)],
          ["yesterday", eq(0)],
          ["week_to_date", be_within(0.01).of(2.0)],
          ["month_to_date", be_within(0.01).of(2.0)],
          ["season_to_date", be_within(0.01).of(2.0)],
        ].each do |window, matcher|
          expect(body["pool_scores"]["scores"][window]).to matcher,
            "pool_scores scores #{window} mismatch"
        end

        expect(body["pool_scores"].keys).to_not include("clipped_scores"),
          "show endpoint should not include clipped pool_scores"

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
end
