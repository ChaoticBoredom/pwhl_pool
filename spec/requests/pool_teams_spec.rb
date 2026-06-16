require "rails_helper"

RSpec.describe "PoolTeams", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league, state: :active) }
  let(:pool_team) { create(:pool_team, pool: pool, owner: user) }
  let(:headers) { auth_headers_for(user) }
  let(:other_headers) { auth_headers_for(other_user) }

  describe "GET /api/pool_teams/:id" do
    before do
      allow(PlayerRecordQuery).to receive(:new).and_return(double(records: {}))
      allow_any_instance_of(PlayerScoringService).to receive(:player_summaries).and_return({})
      allow_any_instance_of(PlayerScoringService).to receive(:team_scores).and_return({ pool_team.id => 0 })
      allow_any_instance_of(UpcomingGamesService).to receive(:player_schedule).and_return({})
    end

    it "returns ok" do
      get "/api/pool_teams/#{pool_team.id}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "requires authentication" do
      get "/api/pool_teams/#{pool_team.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/pool_teams" do
    let(:valid_params) { { team: { team_name: "My Team", pool_id: pool.id } } }

    it "returns created" do
      post "/api/pool_teams", params: valid_params.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it "creates a pool team" do
      expect {
        post "/api/pool_teams", params: valid_params.to_json, headers: headers
      }.to change { Pool::Team.count }.by(1)
    end

    it "requires authentication" do
      post "/api/pool_teams", params: valid_params.to_json
      expect(response).to have_http_status(:unauthorized)
    end

    context "when params are invalid" do
      let(:valid_params) { { team: { team_name: nil, pool_id: pool.id } } }

      it "returns unprocessable_content" do
        post "/api/pool_teams", params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns errors" do
        post "/api/pool_teams", params: valid_params.to_json, headers: headers
        expect(response.parsed_body["errors"]).to be_present
      end
    end
  end

  describe "PUT /api/pool_teams/:id" do
    let(:valid_params) { { pool_team: { team_name: "New Name" } } }

    it "returns ok" do
      put "/api/pool_teams/#{pool_team.id}", params: valid_params.to_json, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "updates the team name" do
      put "/api/pool_teams/#{pool_team.id}", params: valid_params.to_json, headers: headers
      expect(pool_team.reload.team_name).to eq("New Name")
    end

    it "is forbidden for non-owners" do
      put "/api/pool_teams/#{pool_team.id}", params: valid_params.to_json, headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      put "/api/pool_teams/#{pool_team.id}", params: valid_params.to_json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
