require "rails_helper"

RSpec.describe "pool boxes", type: :request do
  include_context "pwhl pool"

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

  describe "commissioner/pool_boxes#generate" do
    it "returns the expected response" do
      post "/api/commissioner/#{pool.id}/pool_boxes/generate",
        headers: auth_headers_for(pool.admin),
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
        expect(body["boxes"].map { |b| b["name"] }).to match_array(["Forwards Box 1", "Goalies Box 1"])
        expect(body).to have_key("free_agents")
        expect(body["free_agents"]).to be_an(Array)

        [
          ["Forwards Box 1", skater.id, be_within(0.01).of(4.5)],
          ["Goalies Box 1", goalie.id, be_within(0.01).of(2.0)],
        ].each do |box_name, player_id, score_matcher|
          box = body["boxes"].find { |b| b["name"] == box_name }
          expect(box["players"]).not_to be_empty, "#{box_name} had no players"
          expect(box["players"].first["id"]).to eq(player_id), "#{box_name} first player id mismatch"
          expect(box["players"].first["score"]).to score_matcher, "#{box_name} first player score mismatch"
          expect(box["players"].first["current_team_short_code"]).to eq("BOS"), "#{box_name} team_short_code mismatch"
        end
      end
    end
  end

  describe "commissioner/pool_boxes#default" do
    it "returns the expected response" do
      get "/api/commissioner/#{pool.id}/pool_boxes/default",
        headers: auth_headers_for(pool.admin)

      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)
        expect(body["boxes"]).to be_an(Array)
        expect(body["boxes"]).to_not be_empty
        expect(body).to have_key("free_agents")
        expect(body["free_agents"]).to be_an(Array)

        body["boxes"].each do |box|
          expect(box["name"]).to be_a(String), "box name should be a string"
          expect(box["players"]).to be_an(Array), "#{box["name"]} should have a players array"
          box["players"].each do |player|
            expect(player["id"]).to be_a(String), "player id should be a string"
            expect(player["name"]).to be_a(String), "player name should be a string"
            expect(player["current_team_short_code"]).to be_a(String), "player team should be a string"
            expect(player["score"]).to be_a(Numeric), "player score should be numeric"
          end
        end

        body["free_agents"].each do |player|
          expect(player["id"]).to be_a(String), "free agent id should be a string"
          expect(player["name"]).to be_a(String), "free agent name should be a string"
          expect(player["current_team_short_code"]).to be_a(String), "free agent team should be a string"
          expect(player["score"]).to be_a(Numeric), "free agent score should be numeric"
        end
      end
    end
  end
end
