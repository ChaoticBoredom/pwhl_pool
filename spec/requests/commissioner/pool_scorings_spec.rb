require "rails_helper"

RSpec.describe "Commissioner::PoolScoring", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, admin: admin, league: league) }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }
  let(:json) { JSON.parse(response.body) }

  describe "PUT /api/commissioner/:pool_id/pool_scoring" do
    let(:valid_params) do
      {
        scoring: [
          { field_name: "goals", roster_type: "skater", value: 2.0 },
          { field_name: "assists", roster_type: "skater", value: 1.0 },
          { field_name: "goals", roster_type: "goalie", value: 5.0 },
          { field_name: "saves", roster_type: "goalie", value: 0.1 },
          { field_name: "hits", roster_type: "skater", value: 0.0 },
          { field_name: "shots", roster_type: "skater", value: nil },
        ],
      }
    end

    it "replaces all scoring records" do
      create(:pool_scoring, :skater, :goals, value: 1.0, pool: pool)

      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: valid_params.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:no_content)
      expect(pool.scoring.find_by(field_name: "goals").value).to eq(2.0)
    end

    it "creates scoring records for each non-zero field" do
      expect {
        put "/api/commissioner/#{pool.id}/pool_scoring",
          params: valid_params.to_json,
          headers: admin_headers
      }.to change { pool.scoring.count }.by(4)
    end

    it "destroys existing scoring records" do
      existing = create(:pool_scoring, :skater, :goals, value: 1.0, pool: pool)

      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: valid_params.to_json,
        headers: admin_headers

      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "skips zero value fields" do
      expect {
        put "/api/commissioner/#{pool.id}/pool_scoring",
          params: { scoring: [
            { field_name: "goals", roster_type: "skater", value: 2.0 },
            { field_name: "assists", roster_type: "skater", value: 0 },
            { field_name: "shots", roster_type: "skater", value: 0.5 },
          ] }.to_json,
          headers: admin_headers
      }.to change { pool.scoring.count }.by(2)
    end

    it "skips unknown fields" do
      expect {
        put "/api/commissioner/#{pool.id}/pool_scoring",
          params: { scoring: [
            { field_name: "goals", roster_type: "skater", value: 2.0 },
            { field_name: "not_a_stat", roster_type: "skater", value: 99.0 },
          ] }.to_json,
          headers: admin_headers
      }.to change { pool.scoring.count }.by(1)
    end

    it "assigns correct roster_type for skater fields" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [
          { field_name: "goals", roster_type: "skater", value: 2.0 },
        ] }.to_json,
        headers: admin_headers

      expect(pool.scoring.find_by(field_name: "goals", roster_type: "skater").value).to eq(2.0)
    end

    it "assigns correct roster_type for goalie fields" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [
          { field_name: "saves", roster_type: "goalie", value: 0.1 },
        ] }.to_json,
        headers: admin_headers

      expect(pool.scoring.find_by(field_name: "saves", roster_type: "goalie").value).to eq(0.1)
    end

    it "is forbidden for non-admins" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: valid_params.to_json,
        headers: other_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: valid_params.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
