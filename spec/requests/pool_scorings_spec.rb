require "rails_helper"

RSpec.describe "PoolScoring#index", type: :request do
  let(:pwhl) { create(:league, :pwhl) }
  let(:user) { create(:user) }
  let(:pool) { create(:pool, league: pwhl) }
  let(:headers) { auth_headers_for(user) }

  context "when scoring exists in the db" do
    let!(:skater_goals) { create(:pool_scoring, :skater, :goals, pool: pool) }
    let!(:skater_assists) { create(:pool_scoring, :skater, :assists, pool: pool) }
    let!(:goalie_wins) { create(:pool_scoring, :goalie, :wins, pool: pool) }

    it "groups the skater rows under the skater roster type" do
      get pool_pool_scoring_index_path(pool), headers: headers

      skater_field_names = response.parsed_body["skater"].
        select { |f| f["id"].present? }.
        map { |f| f["field_name"] }

      expect(skater_field_names).to match_array(["goals", "assists"])
    end

    it "groups the goalie rows under the goalie roster type" do
      get pool_pool_scoring_index_path(pool), headers: headers

      goalie_field_names = response.parsed_body["goalie"].
        select { |f| f["id"].present? }.
        map { |f| f["field_name"] }

      expect(goalie_field_names).to match_array(["win"])
    end

    it "returns the persisted row's id and value rather than the default" do
      get pool_pool_scoring_index_path(pool), headers: headers

      skater_goals_field = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals_field).to match(
        "id" => skater_goals.id,
        "descriptive" => "Goals",
        "field_name" => "goals",
        "value" => 3.0,
      )
    end
  end

  context "when no scoring exists in the db" do
    [
      ["skater", "goals", 2.0],
      ["skater", "assists", 1.0],
      ["skater", "penalty_minutes", 0.25],
      ["skater", "shots", 0.25],
      ["skater", "hits", 0.25],
      ["skater", "plus_minus", 0.0],
      ["skater", "power_play_goals", 1.0],
      ["skater", "short_handed_goals", 2.0],
      ["skater", "shots_blocked", 0.0],
      ["skater", "faceoffs_taken", 0.0],
      ["skater", "faceoffs_won", 0.0],
      ["skater", "game_winning_goals", 0.0],
      ["goalie", "goals", 5.0],
      ["goalie", "assists", 2.0],
      ["goalie", "goals_against", 0.0],
      ["goalie", "shots_against", 0.0],
      ["goalie", "penalty_minutes", 0.25],
      ["goalie", "win", 2.0],
      ["goalie", "shutout", 2.0],
      ["goalie", "saves", 0.05],
      ["goalie", "game_started", 0.0],
    ].each do |roster_type, field_name, default_value|
      it "returns #{default_value} for #{roster_type}/#{field_name}" do
        get pool_pool_scoring_index_path(pool), headers: headers

        field = response.parsed_body[roster_type].find { |f| f["field_name"] == field_name }

        expect(field["value"]).to eq(default_value)
      end
    end

    it "returns a nil id since no row has been created yet" do
      get pool_pool_scoring_index_path(pool), headers: headers

      skater_goals_field = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals_field["id"]).to be_nil
    end
  end
end
