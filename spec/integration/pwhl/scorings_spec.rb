require "rails_helper"

RSpec.describe "scorings", type: :request do
  include_context "pwhl pool"

  describe "scorings#index" do
    # The shared context only has 6 scorings set up, but the index action
    # should return ALL scoreable fields. The 6 that exist should use their
    # DB values, while all others should return as '0'
    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        [
          ["skater", "goals", 2.0],
          ["skater", "assists", 1.0],
          ["skater", "shots", 0.5],
          ["skater", "hits", 0.5],
          ["goalie", "win", 2.0],
          ["goalie", "saves", 0.1],
        ].each do |stat_type, field, value|
          entry = body[stat_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(value),
            "#{stat_type} #{field} value mismatch: expected #{value.inspect}, got #{entry["value"].inspect}"
        end

        [
          ["skater", "penalty_minutes"],
          ["skater", "plus_minus"],
          ["skater", "power_play_goals"],
          ["skater", "short_handed_goals"],
          ["skater", "shots_blocked"],
          ["skater", "faceoffs_taken"],
          ["skater", "faceoffs_won"],
          ["skater", "game_winning_goals"],
          ["goalie", "goals"],
          ["goalie", "assists"],
          ["goalie", "goals_against"],
          ["goalie", "penalty_minutes"],
          ["goalie", "shutout"],
          ["goalie", "game_started"],
        ].each do |stat_type, field|
          entry = body[stat_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(0.0),
            "#{stat_type} #{field} should fall back to 0, got #{entry["value"].inspect}"
          expect(entry["id"]).to be_nil
        end
      end
    end
  end
end
