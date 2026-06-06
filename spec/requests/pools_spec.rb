require "rails_helper"

RSpec.describe "Pools", type: :request do
  let(:user) { create(:user) }
  let(:league) { create(:league) }
  let(:headers) { auth_headers_for(user) }
  let(:json) { JSON.parse(response.body) }

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
