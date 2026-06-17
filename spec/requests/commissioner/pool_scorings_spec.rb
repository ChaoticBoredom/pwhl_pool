require "rails_helper"

RSpec.describe "Commissioner::PoolScoring", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pwhl) { create(:league, :pwhl) }
  let(:pool) { create(:pool, admin: admin, league: pwhl) }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }

  describe "POST /api/commissioner/:pool_id/pool_scoring" do
    let(:full_scoring_params) do
      {
        scoring: [
          { field_name: "goals", roster_type: "skater", value: 2.0 },
          { field_name: "assists", roster_type: "skater", value: 1.0 },
          { field_name: "penalty_minutes", roster_type: "skater", value: 0.25 },
          { field_name: "shots", roster_type: "skater", value: 0.25 },
          { field_name: "hits", roster_type: "skater", value: 0.25 },
          { field_name: "plus_minus", roster_type: "skater", value: 0.0 },
          { field_name: "power_play_goals", roster_type: "skater", value: 1.0 },
          { field_name: "short_handed_goals", roster_type: "skater", value: 2.0 },
          { field_name: "shots_blocked", roster_type: "skater", value: 0.0 },
          { field_name: "faceoffs_taken", roster_type: "skater", value: 0.0 },
          { field_name: "faceoffs_won", roster_type: "skater", value: 0.0 },
          { field_name: "game_winning_goals", roster_type: "skater", value: 0.0 },
          { field_name: "goals", roster_type: "goalie", value: 5.0 },
          { field_name: "assists", roster_type: "goalie", value: 2.0 },
          { field_name: "goals_against", roster_type: "goalie", value: 0.0 },
          { field_name: "shots_against", roster_type: "goalie", value: 0.0 },
          { field_name: "penalty_minutes", roster_type: "goalie", value: 0.25 },
          { field_name: "win", roster_type: "goalie", value: 2.0 },
          { field_name: "shutout", roster_type: "goalie", value: 2.0 },
          { field_name: "saves", roster_type: "goalie", value: 0.05 },
          { field_name: "game_started", roster_type: "goalie", value: 0.0 },
        ],
      }
    end

    it "creates a row for every submitted field" do
      expect {
        post "/api/commissioner/#{pool.id}/pool_scoring",
          params: full_scoring_params.to_json,
          headers: admin_headers
      }.to change { pool.scoring.count }.by(21)
    end

    it "persists a zero value rather than dropping it" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: admin_headers

      expect(pool.scoring.find_by(field_name: "plus_minus", roster_type: "skater").value).to eq(0.0)
    end

    it "returns the created rows grouped by roster type" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: admin_headers

      skater_goals = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals["value"]).to eq(2.0)
    end

    it "returns a 201" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:created)
    end

    it "rejects a submission missing a scoreable field" do
      incomplete_params = { scoring: full_scoring_params[:scoring].reject { |f| f[:field_name] == "goals" } }

      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: incomplete_params.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create any rows when the submission is missing a field" do
      incomplete_params = { scoring: full_scoring_params[:scoring].reject { |f| f[:field_name] == "goals" } }

      expect {
        post "/api/commissioner/#{pool.id}/pool_scoring",
          params: incomplete_params.to_json,
          headers: admin_headers
      }.to_not change { pool.scoring.count }
    end

    it "rejects a submission containing a field outside SCOREABLE_STATS" do
      junk_params = {
        scoring: full_scoring_params[:scoring] + [
          { field_name: "not_a_real_stat", roster_type: "skater", value: 1.0 },
        ],
      }

      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: junk_params.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a second create call once scoring already exists for the pool" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: admin_headers

      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is forbidden for non-admins" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json,
        headers: other_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/commissioner/#{pool.id}/pool_scoring",
        params: full_scoring_params.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/commissioner/:pool_id/pool_scoring" do
    let!(:goals) { create(:pool_scoring, :skater, :goals, value: 2.0, pool: pool) }
    let!(:assists) { create(:pool_scoring, :skater, :assists, value: 1.0, pool: pool) }

    it "updates the value for a submitted row" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 3.0 }] }.to_json,
        headers: admin_headers

      expect(goals.reload.value).to eq(3.0)
    end

    it "leaves a row untouched when it is not part of the submission" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 3.0 }] }.to_json,
        headers: admin_headers

      expect(assists.reload.value).to eq(1.0)
    end

    it "persists an explicit zero rather than rejecting it" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 0.0 }] }.to_json,
        headers: admin_headers

      expect(goals.reload.value).to eq(0.0)
    end

    it "returns a 200" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 3.0 }] }.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:ok)
    end

    it "responds 404 when an id does not belong to the pool" do
      other_pool_scoring = create(:pool_scoring, :skater, :goals)

      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: other_pool_scoring.id, value: 3.0 }] }.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end

    it "is forbidden for non-admins" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 3.0 }] }.to_json,
        headers: other_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      put "/api/commissioner/#{pool.id}/pool_scoring",
        params: { scoring: [{ id: goals.id, value: 3.0 }] }.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
