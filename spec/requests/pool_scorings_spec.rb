require "rails_helper"

RSpec.describe "PoolScoring#index", type: :request do
  let(:pwhl) { create(:league, :pwhl) }
  let(:user) { create(:user) }
  let(:pool) { create(:pool, league: pwhl) }
  let(:headers) { auth_headers_for(user) }

  let(:skater_fields) do
    [
      "goals", "assists", "penalty_minutes", "shots", "hits", "plus_minus",
      "power_play_goals", "short_handed_goals", "shots_blocked",
      "faceoffs_taken", "faceoffs_won", "game_winning_goals"
    ]
  end
  let(:goalie_fields) do
    [
      "goals", "assists", "goals_against", "shots_against", "penalty_minutes",
      "win", "shutout", "saves", "game_started"
    ]
  end

  shared_examples "returns every scoreable field" do
    it "returns every skater field" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      expect(response.parsed_body["skater"].pluck("field_name")).to match_array(skater_fields)
    end

    it "returns every goalie field" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      expect(response.parsed_body["goalie"].pluck("field_name")).to match_array(goalie_fields)
    end
  end

  context "when no scoring exists in the db" do
    it_behaves_like "returns every scoreable field"

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
    ].each do |stat_type, field_name, default_value|
      it "returns #{default_value} for #{stat_type}/#{field_name}" do
        get "/api/pools/#{pool.id}/pool_scoring", headers: headers

        field = response.parsed_body[stat_type].find { |f| f["field_name"] == field_name }

        expect(field["value"]).to eq(default_value)
      end
    end

    it "returns a nil id since no row has been created yet" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      skater_goals_field = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals_field["id"]).to be_nil
    end
  end

  context "when scoring exists in the db" do
    let!(:skater_goals) { create(:pool_scoring, :skater, :goals, pool: pool) }
    let!(:skater_assists) { create(:pool_scoring, :skater, :assists, pool: pool) }
    let!(:goalie_wins) { create(:pool_scoring, :goalie, :wins, pool: pool) }

    it_behaves_like "returns every scoreable field"

    it "groups the skater rows under the skater stat type" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      skater_field_names = response.parsed_body["skater"].
        map { |f| f["field_name"] }

      expect(skater_field_names).to include("goals", "assists")
    end

    it "groups the goalie rows under the goalie stat type" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      goalie_field_names = response.parsed_body["goalie"].
        map { |f| f["field_name"] }

      expect(goalie_field_names).to include("win")
    end

    it "returns the persisted row's id and value rather than the default" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers

      skater_goals_field = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals_field).to match(
        "id" => skater_goals.id,
        "descriptive" => "Goals",
        "stat_type" => "skater",
        "field_name" => "goals",
        "value" => 3.0,
      )
    end
  end

  context "when pool has some scoring, but is missing others" do
    let!(:goals) { create(:pool_scoring, :skater, :goals, pool: pool) }

    it_behaves_like "returns every scoreable field"

    it "returns 0 for a field with no row when any row exists" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers
      # Default value is 1.0, only goals is present in DB
      skater_assists = response.parsed_body["skater"].find { |f| f["field_name"] == "hits" }

      expect(skater_assists["value"]).to eq(0.0)
    end

    it "returns a nil id for a field with no row" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers
      skater_assists = response.parsed_body["skater"].find { |f| f["field_name"] == "hits" }

      expect(skater_assists["id"]).to be_nil
    end

    it "returns the db value for any row that is saved" do
      # Default value for hits would be 0.25
      create(:pool_scoring, :skater, :hits, pool: pool, value: 0)
      get "/api/pools/#{pool.id}/pool_scoring", headers: headers
      skater_hits = response.parsed_body["skater"].find { |f| f["field_name"] == "hits" }

      expect(skater_hits["value"]).to eq(0.0)
    end

    it "still returns the field that does have a row" do
      get pool_pool_scoring_index_path(pool), headers: headers
      skater_goals_field = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals_field["id"]).to eq(goals.id)
    end
  end
end
