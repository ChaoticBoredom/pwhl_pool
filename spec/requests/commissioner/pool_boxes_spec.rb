require "rails_helper"

RSpec.describe "Commissioner::PoolBoxes", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pool) { create(:pool, admin: admin, state: :draft) }
  let(:season_id) { pool.display_season_id }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }
  let(:json) { JSON.parse(response.body) }

  describe "GET /api/commissioner/:pool_id/pool_boxes/default" do
    let(:pool) { create(:pool, admin: admin, league: create(:league, :pwhl)) }

    subject(:get_default) do
      get "/api/commissioner/#{pool.id}/pool_boxes/default",
        headers: admin_headers
    end

    it "returns ok" do
      get_default

      expect(response).to have_http_status(:ok)
    end

    it "returns a boxes array" do
      get_default

      expect(response.parsed_body["boxes"]).to be_an(Array)
    end

    it "returns the expected number of boxes" do
      get_default

      expect(response.parsed_body["boxes"].length).to eq(BoxGeneration::DEFAULT_BOXES.length)
    end

    it "returns boxes with the expected names" do
      get_default

      names = response.parsed_body["boxes"].map { |b| b["name"] }
      expect(names).to match_array(BoxGeneration::DEFAULT_BOXES.map(&:name))
    end

    it "caches the result" do
      expect(BoxGenerationService).to receive(:new).once.and_call_original

      get_default
      get_default
    end

    it "uses a cache key independent of the pool" do
      other_pool = create(:pool, admin: create(:user), league: pool.league, season_id: pool.season_id)

      expected_key = "pool_boxes/default/#{pool.league_id}/#{pool.display_season_id}"

      expect(Rails.cache).to receive(:fetch).with(expected_key, anything).at_least(:twice).and_call_original

      get "/api/commissioner/#{pool.id}/pool_boxes/default", headers: admin_headers
      get "/api/commissioner/#{other_pool.id}/pool_boxes/default",
        headers: auth_headers_for(other_pool.admin)
    end

    it "is forbidden for non-admins" do
      get "/api/commissioner/#{pool.id}/pool_boxes/default",
        headers: other_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/commissioner/#{pool.id}/pool_boxes/default"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /pools/:pool_id/pool_boxes/generate" do
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
        "Goalies Box 1" => [
          { id: SecureRandom.uuid, name: "Aerin Frankel", score: 85.55, team_short_code: "BOS" },
        ],
      }
    end

    let(:fake_service) { instance_double(BoxGenerationService, call: fake_result) }

    subject(:post_generate) do
      post "/api/commissioner/#{pool.id}/pool_boxes/generate",
        params: generate_params.to_json,
        headers: admin_headers
    end

    before { allow(BoxGenerationService).to receive(:new).and_return(fake_service) }

    context "when unauthenticated" do
      it "returns 401" do
        post "/api/commissioner/#{pool.id}/pool_boxes/generate"
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
        expect(box_names).to match_array(["Forwards Box 1", "Defence Box 1", "Goalies Box 1"])
      end

      it "renders player id as a string within each box" do
        post_generate
        player = response.parsed_body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"].first
        expect(player["id"]).to be_a(String)
      end

      [
        ["name", "Laura Stacey"],
        ["score", 71.25],
        ["current_team_short_code", "MTL"],
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
          hash_including(teams: ["MTL", "OTT"], scope: "per_team"),
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
