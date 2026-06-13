require "rails_helper"

RSpec.describe "Commissioner::PoolBoxes", type: :request do
  include_context "pwhl teams"

  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pool) { create(:pool, admin: admin, state: :draft, league: pwhl) }
  let(:season_id) { pool.display_season_id }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }
  let(:json) { JSON.parse(response.body) }
  let(:boston) { team("1") }
  let(:minnesota) { team("2") }

  describe "GET /api/commissioner/:pool_id/pool_boxes" do
    let(:player_1) { create(:pwhl_skater, league: pwhl, name: "Taylor Heise", position: "F", current_team: minnesota) }
    let(:player_2) { create(:pwhl_skater, league: pwhl, name: "Megan Keller", position: "D", current_team: boston) }
    let!(:box_1) do
      create(:pool_box,
        pool: pool,
        name: "Forwards Box 1",
        league_player_ids: [player_1.id]
      )
    end
    let!(:box_2) do
      create(:pool_box,
        pool: pool,
        name: "Defence Box 1",
        league_player_ids: [player_2.id]
      )
    end

    let(:fake_scores) do
      {
        player_1.id => { scores: { season_to_date: 76.5 } },
        player_2.id => { scores: { season_to_date: 66.5 } },
      }
    end

    before do
      allow(PlayerRecordQuery).to receive(:new).and_return(double(records: {}))
      allow_any_instance_of(PlayerScoringService).to receive(:raw_player_summaries).and_return({
        player_1.id => { scores: { season_to_date: 76.5 } },
        player_2.id => { scores: { season_to_date: 66.5 } },
      })
      allow_any_instance_of(Commissioner::PoolBoxesController).to receive(:compute_free_agents).and_return([])
    end

    subject(:get_index) do
      get "/api/commissioner/#{pool.id}/pool_boxes", headers: admin_headers
    end

    it "returns ok" do
      get_index
      expect(response).to have_http_status(:ok)
    end

    it "returns a boxes array" do
      get_index
      expect(response.parsed_body["boxes"]).to be_an(Array)
    end

    it "returns the expected box names" do
      get_index
      names = response.parsed_body["boxes"].map { |b| b["name"] }
      expect(names).to match_array(["Forwards Box 1", "Defence Box 1"])
    end

    it "returns players within each box" do
      get_index
      players = response.parsed_body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"]
      expect(players.length).to eq(1)
    end

    [
      ["name", "Taylor Heise"],
      ["position", "F"],
      ["current_team_short_code", "MIN"],
      ["score", 76.5],
      ["rookie", false],
    ].each do |field, value|
      it "renders player #{field}" do
        get_index
        player = response.parsed_body["boxes"].find { |b| b["name"] == "Forwards Box 1" }["players"].first
        expect(player[field]).to eq(value)
      end
    end

    it "is forbidden for non-admins" do
      get "/api/commissioner/#{pool.id}/pool_boxes", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/commissioner/#{pool.id}/pool_boxes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/commissioner/:pool_id/pool_boxes" do
    let(:player_id_1) { SecureRandom.uuid }
    let(:player_id_2) { SecureRandom.uuid }

    let(:valid_params) do
      {
        boxes: [
          { name: "Forwards Box 1", position: 1, players: [{ id: player_id_1 }] },
          { name: "Defence Box 1", position: 2, players: [{ id: player_id_2 }] },
        ],
      }
    end

    subject(:post_create) do
      post "/api/commissioner/#{pool.id}/pool_boxes",
        params: valid_params.to_json,
        headers: admin_headers
    end

    context "when the pool is in draft state" do
      it "returns created" do
        post_create
        expect(response).to have_http_status(:created)
      end

      it "creates the boxes" do
        expect { post_create }.to change { pool.pool_boxes.active.count }.by(2)
      end

      it "returns a boxes array" do
        post_create
        expect(response.parsed_body["boxes"]).to be_an(Array)
      end
    end

    context "when the service fails" do
      before do
        allow(BoxReplacementService).to receive(:new).and_return(
          instance_double(BoxReplacementService, call: BoxReplacementService::Result.new(success: false, errors: ["something went wrong"]))
        )
      end

      it "returns unprocessable_content" do
        post_create
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns the errors" do
        post_create
        expect(response.parsed_body["errors"]).to eq(["something went wrong"])
      end
    end

    it "is forbidden for non-admins" do
      post "/api/commissioner/#{pool.id}/pool_boxes",
        params: valid_params.to_json,
        headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/commissioner/#{pool.id}/pool_boxes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/commissioner/:pool_id/pool_boxes" do
    let(:player_id_1) { SecureRandom.uuid }
    let(:player_id_2) { SecureRandom.uuid }
    let!(:existing_box) { create(:pool_box, pool: pool, name: "Old Box", position: 1) }

    let(:valid_params) do
      {
        boxes: [
          { name: "Forwards Box 1", position: 1, players: [{ id: player_id_1 }] },
        ],
      }
    end

    subject(:put_update) do
      put "/api/commissioner/#{pool.id}/pool_boxes",
        params: valid_params.to_json,
        headers: admin_headers
    end

    context "when the pool is in draft state" do
      it "returns created" do
        put_update
        expect(response).to have_http_status(:created)
      end

      it "replaces existing boxes" do
        put_update
        expect(pool.pool_boxes.active.map(&:name)).to eq(["Forwards Box 1"])
      end
    end

    context "when the pool is active" do
      let(:pool) { create(:pool, admin: admin, state: :active) }

      it "returns created" do
        put_update
        expect(response).to have_http_status(:created)
      end

      it "deactivates existing boxes" do
        put_update
        expect(existing_box.reload.active).to be(false)
      end
    end

    it "is forbidden for non-admins" do
      put "/api/commissioner/#{pool.id}/pool_boxes",
        params: valid_params.to_json,
        headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      put "/api/commissioner/#{pool.id}/pool_boxes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/commissioner/:pool_id/pool_boxes/default" do
    let(:pool) { create(:pool, admin: admin, league: pwhl) }
    let(:fake_result) do
      {
        "Forwards Box 1" => {
          position: 1,
          players: [{ id: SecureRandom.uuid, name: "Taylor Heise", score: 76.5, current_team_short_code: "MIN" }],
        },
      }
    end
    let(:fake_service) { instance_double(BoxGenerationService, call: fake_result) }

    before(:each) { allow(BoxGenerationService).to receive(:new).and_return(fake_service) }

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

      expect(response.parsed_body["boxes"].length).to eq(fake_result.length)
    end

    it "returns boxes with the expected names" do
      get_default

      names = response.parsed_body["boxes"].map { |b| b["name"] }
      expect(names).to match_array(fake_result.keys)
    end

    it "caches the result" do
      expect(BoxGenerationService).to receive(:new).once.and_return(fake_service)

      get_default
      get_default
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
        "Forwards Box 1" => {
          position: 1,
          players: [
            { id: SecureRandom.uuid, name: "Laura Stacey", score: 71.25, current_team_short_code: "MTL" },
            { id: SecureRandom.uuid, name: "Brianne Jenner", score: 72.75, current_team_short_code: "OTT" },
          ],
        },
        "Defence Box 1" => {
          position: 2,
          players: [
            { id: SecureRandom.uuid, name: "Maggie Flaherty", score: 40.25, current_team_short_code: "MTL" },
          ],
        },
        "Goalies Box 1" => {
          position: 3,
          players: [
            { id: SecureRandom.uuid, name: "Aerin Frankel", score: 85.55, current_team_short_code: "BOS" },
          ],
        },
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
