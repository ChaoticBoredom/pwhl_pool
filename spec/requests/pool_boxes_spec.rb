require "rails_helper"

RSpec.describe "PoolBoxes", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }
  let(:pool) { create(:pool, league: create(:league, :pwhl)) }
  let(:season_id) { pool.display_season_id }

  describe "GET /pools/:pool_id/boxes" do
    subject(:get_index) { get "/api/pools/#{pool.id}/pool_boxes", headers: auth_headers }

    context "when unauthenticated" do
      it "returns 401" do
        get "/api/pools/#{pool.id}/pool_boxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no boxes" do
      it "returns an empty boxes array" do
        get_index
        expect(response.parsed_body["boxes"]).to eq([])
      end
    end

    context "with boxes and players" do
      let(:player_a) { create(:pwhl_skater, league: pool.league) }
      let(:player_b) { create(:pwhl_skater, league: pool.league) }
      let!(:box) { create(:pool_box, pool: pool, league_player_ids: [player_a.id, player_b.id]) }

      before do
        allow(PlayerRecordQuery).to receive(:new).and_return(
          instance_double(PlayerRecordQuery, records: {})
        )
        allow_any_instance_of(PlayerScoringService).to receive(:raw_player_summaries).and_return(
          player_a.id => { today: 1.0, yesterday: 2.0, week_to_date: 3.0, month_to_date: 4.0, season_to_date: 5.0 },
          player_b.id => { today: 0.0, yesterday: 0.0, week_to_date: 0.0, month_to_date: 0.0, season_to_date: 10.0 },
        )
      end

      it "returns 200" do
        get_index
        expect(response).to have_http_status(:ok)
      end

      it "initialises PlayerRecordQuery with players: and season_id:" do
        expect(PlayerRecordQuery).to receive(:new).with(
          players: match_array([player_a, player_b]),
          season_id: season_id,
        ).and_return(instance_double(PlayerRecordQuery, records: {}))
        get_index
      end

      [
        ["id", :id],
        ["name", :name],
        ["order", :position],
      ].each do |field, expected|
        it "renders box #{field}" do
          get_index
          expect(response.parsed_body["boxes"].first[field]).to eq(box[expected])
        end
      end

      [
        ["today", 1.0],
        ["yesterday", 2.0],
        ["week_to_date", 3.0],
        ["month_to_date", 4.0],
        ["season_to_date", 5.0],
      ].each do |window, value|
        it "renders #{window} score for each player" do
          get_index
          scores = response.parsed_body["boxes"].first["players"].
            find { |p| p["id"] == player_a.id }["scores"]
          expect(scores[window]).to eq(value)
        end
      end

      context "when the current user has a pool team" do
        let!(:pool_team) { create(:pool_team, pool: pool, owner: user) }

        it "marks a player on the current team as selected" do
          create(:pool_team_player, pool_team: pool_team, league_player: player_a)
          get_index
          players = response.parsed_body["boxes"].first["players"]
          expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(true)
        end

        it "marks a player not on the current team as not selected" do
          get_index
          players = response.parsed_body["boxes"].first["players"]
          expect(players.find { |p| p["id"] == player_a.id }["selected"]).to be(false)
        end
      end

      context "when the current user has no pool team" do
        it "marks all players as not selected" do
          get_index
          players = response.parsed_body["boxes"].first["players"]
          expect(players.map { |p| p["selected"] }).to all(be(false))
        end
      end

      context "with an inactive box" do
        let!(:inactive_box) do
          create(:pool_box, pool: pool, league_player_ids: [player_a.id], active: false)
        end

        it "does not return inactive boxes" do
          get_index
          box_names = response.parsed_body["boxes"].map { |b| b["name"] }
          expect(box_names).to_not include(inactive_box.name)
        end
      end
    end
  end

  describe "POST /pools/:pool_id/pool_boxes/generate" do
    let(:pool) { create(:pool, league: create(:league, :pwhl)) }

    let(:generate_params) do
      {
        teams: ["MTL", "OTT"],
        scope: "per_team",
        season_id: season_id,
        excluded_player_ids: [],
        boxes: [
          { name: "Forwards Box 1", position: "F", rookie: false, rank: 1, count: 1 },
          { name: "Defence Box 1", position: "D", rookie: false, rank: 1, count: 1 },
          { name: "Goalies Box 1", position: "G", rookie: nil, rank: 1, count: 1 },
        ],
      }
    end

    let(:fake_result) do
      {
        "Forwards Box 1" => [
          { id: SecureRandom.uuid, name: "Laura Stacey", score: 71.25, team_short_code: "MTL" },
          { id: SecureRandom.uuid, name: "Brianne Jenner", score: 72.75, team_short_code: "OTT" },
        ],
        "Defence Box 1" => [
          { id: SecureRandom.uuid, name: "Maggie Flaherty", score: 40.25, team_short_code: "MTL" },
        ],
      }
    end

    let(:fake_service) { instance_double(BoxGenerationService, call: fake_result) }

    subject(:post_generate) do
      post "/api/pools/#{pool.id}/pool_boxes/generate",
        params: generate_params.to_json,
        headers: auth_headers.merge("Content-Type" => "application/json")
    end

    before { allow(BoxGenerationService).to receive(:new).and_return(fake_service) }

    context "when unauthenticated" do
      it "returns 401" do
        post "/api/pools/#{pool.id}/pool_boxes/generate"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid params" do
      it "returns 200" do
        post_generate
        expect(response).to have_http_status(:ok)
      end

      it "returns a boxes array keyed by name" do
        post_generate
        box_names = response.parsed_body["boxes"].map { |b| b["name"] }
        expect(box_names).to match_array(["Forwards Box 1", "Defence Box 1"])
      end

      it "renders player id as a string within each box" do
        post_generate
        player = response.parsed_body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"].first
        expect(player["id"]).to be_a(String)
      end

      [
        ["name",            "Laura Stacey"],
        ["score",           71.25],
        ["team_short_code", "MTL"],
      ].each do |field, value|
        it "renders player #{field} within each box" do
          post_generate
          player = response.parsed_body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"].first
          expect(player[field]).to eq(value)
        end
      end

      it "passes season_id to the service" do
        expect(BoxGenerationService).to receive(:new).with(
          pool,
          an_instance_of(BoxGeneration::Config),
          season_id: season_id.to_s,
        ).and_return(fake_service)
        post_generate
      end

      it "passes teams and scope through to the config" do
        expect(BoxGeneration::Config).to receive(:new).with(
          hash_including(teams: ["MTL", "OTT"], scope: "per_team")
        ).and_call_original
        post_generate
      end
    end

    context "when BoxGenerationService raises BoxGenerationError" do
      before do
        allow(fake_service).to receive(:call).and_raise(
          BoxGenerationService::BoxGenerationError, "not enough players"
        )
      end

      it "returns 422" do
        post_generate
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns the error message" do
        post_generate
        expect(response.parsed_body["error"]).to eq("not enough players")
      end
    end
  end
end
