require "rails_helper"

RSpec.describe "Pools", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user) }
  let(:league) { create(:league) }
  let(:headers) { auth_headers_for(user) }
  let(:json) { JSON.parse(response.body) }

  describe "GET /api/pools/:id" do
    let(:pool) { create(:pool, admin: admin, league: league) }
    let(:pool_team) { create(:pool_team, pool: pool, owner: user) }

    context "when the user is a pool member" do
      before { pool_team }

      it "returns ok" do
        get "/api/pools/#{pool.id}", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns the pool id and name" do
        get "/api/pools/#{pool.id}", headers: headers

        expect(json["id"]).to eq(pool.id)
        expect(json["name"]).to eq(pool.name)
      end

      it "returns league details" do
        get "/api/pools/#{pool.id}", headers: headers

        expect(json["league"]["id"]).to eq(league.id)
      end

      it "returns pool teams" do
        get "/api/pools/#{pool.id}", headers: headers

        expect(json["pool_teams"].map { |t| t["id"] }).to include(pool_team.id)
      end
    end

    context "when the user is the admin but not a pool member" do
      it "returns ok" do
        get "/api/pools/#{pool.id}", headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the pool does not exist" do
      it "returns 404" do
        get "/api/pools/#{SecureRandom.uuid}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    it "requires authentication" do
      get "/api/pools/#{pool.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/pools" do
    it "returns pools the user is a member of" do
      pool = create(:pool, admin: admin, league: league)
      create(:pool_team, pool: pool, owner: user)

      get "/api/pools", headers: headers

      expect(json.map { |p| p["id"] }).to include(pool.id)
    end

    it "returns pools the user administers" do
      pool = create(:pool, admin: user, league: league)

      get "/api/pools", headers: headers

      expect(json.map { |p| p["id"] }).to include(pool.id)
    end

    it "does not return pools the user has no relation to" do
      other_user = create(:user)
      pool = create(:pool, admin: other_user, league: league)

      get "/api/pools", headers: headers

      expect(json.map { |p| p["id"] }).to_not include(pool.id)
    end

    it "requires authentication" do
      get "/api/pools"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/pools/meta" do
    before(:each) { league }

    it "returns leagues" do
      get "/api/pools/meta", headers: headers

      expect(json["leagues"]).to eq([{
        "id" => league.id,
        "name" => league.name,
        "short_name" => league.short_name,
      }])
    end

    it "returns seasons" do
      get "/api/pools/meta", headers: headers

      expect(json["seasons"]).to eq([
        { "name" => "2025-26 Regular Season", "id" => "8" },
        { "name" => "2025-26 Playoffs", "id" => "9" },
      ])
    end

    it "returns pool_types" do
      get "/api/pools/meta", headers: headers

      expect(json["pool_types"]).to match_array(Pool.pool_types.keys)
    end

    it "returns trade_policies" do
      get "/api/pools/meta", headers: headers

      expect(json["trade_policies"]).to match_array(Pool.trade_policies.keys)
    end

    it "requires authentication" do
      get "/api/pools/meta"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/pools" do
    let(:valid_params) do
      {
        pool: {
          name: "Test Pool",
          pool_type: "box_select",
          league_id: league.id,
          season_id: "9",
          trade_policy: "disabled",
        },
      }
    end
    let(:payload) { valid_params.to_json }

    it "creates a pool in draft state" do
      expect {
        post "/api/pools", params: payload, headers: headers
      }.to change { Pool.count }.by(1)

      expect(response).to have_http_status(:created)
    end

    it "assigns the current user as admin" do
      post "/api/pools", params: payload, headers: headers

      expect(Pool.last.admin).to eq(user)
    end

    it "returns the created pool" do
      post "/api/pools", params: payload, headers: headers

      expect(json["id"]).to eq(Pool.last.id)
    end

    context "with a valid reference_season_id" do
      it "creates the pool" do
        expect {
          post "/api/pools",
            params: valid_params.deep_merge(pool: { reference_season_id: "8" }).to_json,
            headers: headers
        }.to change { Pool.count }.by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      [
        ["missing name", { name: nil }, "Name"],
        ["matching reference and season", { reference_season_id: "9" }, "Reference season"],
        ["blank pool_type", { pool_type: nil }, "Pool type"],
        ["missing league", { league_id: nil }, "League"],
      ].each do |description, overrides, expected_error_match|
        it "rejects #{description}" do
          post "/api/pools",
            params: valid_params.deep_merge(pool: overrides).to_json,
            headers: headers

          expect(response).to have_http_status(:unprocessable_content)
        end

        it "returns an error mentioning #{expected_error_match} for #{description}" do
          post "/api/pools",
            params: valid_params.deep_merge(pool: overrides).to_json,
            headers: headers

          expect(json["errors"].join).to match(/#{expected_error_match}/i)
        end
      end
    end

    it "requires authentication" do
      expect {
        post "/api/pools", params: payload
      }.to_not change { Pool.count }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
