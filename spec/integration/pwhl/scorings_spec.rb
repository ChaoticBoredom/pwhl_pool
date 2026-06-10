require "rails_helper"

RSpec.describe "scorings", type: :request do
  include_context "pwhl pool"

  describe "scorings#index" do
    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["skater"].map { |s| s["field_name"] }).to match_array(%w[
          goals assists shots hits penalty_minutes plus_minus power_play_goals
          short_handed_goals shots_blocked faceoffs_taken faceoffs_won
          game_winning_goals
        ])

        expect(body["goalie"].map { |s| s["field_name"] }).to match_array(%w[
          win saves goals assists goals_against shots_against penalty_minutes
          shutout game_started
        ])

        [
          ["skater", "goals", 2.0],
          ["skater", "assists", 1.0],
          ["skater", "shots", 0.5],
          ["skater", "hits", 0.5],
          ["goalie", "win", 2.0],
          ["goalie", "saves", 0.1],
          ["skater", "penalty_minutes", nil],
          ["skater", "plus_minus", nil],
          ["skater", "power_play_goals", nil],
          ["skater", "short_handed_goals", nil],
          ["skater", "shots_blocked", nil],
          ["skater", "faceoffs_taken", nil],
          ["skater", "faceoffs_won", nil],
          ["skater", "game_winning_goals", nil],
          ["goalie", "assists", nil],
          ["goalie", "goals_against", nil],
          ["goalie", "shots_against", nil],
          ["goalie", "penalty_minutes", nil],
          ["goalie", "shutout", nil],
          ["goalie", "game_started", nil],
        ].each do |roster_type, field, value|
          entry = body[roster_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(value),
            "#{roster_type} #{field} value mismatch: expected #{value.inspect}, got #{entry["value"].inspect}"
        end
      end
    end
  end
end
