require "rails_helper"

RSpec.describe "PoolTeams", type: :request do
  let(:user) { create(:user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:pool_team) { create(:pool_team, pool: pool, owner: user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }
  let(:skater1) { create(:league_player, :skater, league: league) }
  let(:skater2) { create(:league_player, :skater, league: league) }
  let(:skater3) { create(:league_player, :skater, league: league) }
  let(:skater4) { create(:league_player, :skater, league: league) }

  let!(:current_team1) { create(:pool_team_player, pool_team: pool_team, league_player: skater1) }
  let!(:current_team2) { create(:pool_team_player, pool_team: pool_team, league_player: skater2) }

  describe "POST /update_roster" do
    before(:each) { allow_any_instance_of(Pool).to receive(:trading_allowed_now?).and_return(true) }

    context "when user does not own the team" do
      let(:other_user) { create(:user) }

      it "returns a 403 forbidden" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(other_user)

        expect(response).to have_http_status(:forbidden)
      end

      it "does not alter the pool team" do
        initial_ids = pool_team.current_team.pluck(:league_player_id)
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(other_user)

        expect(pool_team.current_team.pluck(:league_player_id)).to match_array(initial_ids)
      end
    end

    context "when trades are not allowed" do
      before(:each) { allow_any_instance_of(Pool).to receive(:trading_allowed_now?).and_return(false) }
      it "returns a 403 forbidden" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

        expect(response).to have_http_status(:forbidden)
      end

      it "returns a sensible error message" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

        expect(JSON.parse(response.body)["error"]).to eq("Trades are currently locked for this pool")
      end


      it "does not alter the pool team" do
        initial_ids = pool_team.current_team.pluck(:league_player_id)
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

        expect(pool_team.current_team.pluck(:league_player_id)).to match_array(initial_ids)
      end
    end

    context "when trades go through" do
      it "returns a 200" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater3.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

        expect(response).to have_http_status(:ok)
      end

      it "removes ids not in hash" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater1.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

        expect(pool_team.current_team.pluck(:league_player_id)).to_not include(skater2.id)
      end

      it "marks removed players with current time" do
        freeze_time do
          post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater1.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

          expect(current_team2.reload.dropped_at).to eq(Time.current)
        end
      end

      it "adds new ids in the hash" do
        post "/api/pool_teams/#{pool_team.id}/update_roster",
          params: { new_player_ids: [skater1.id, skater4.id] }.to_json,
          headers: auth_headers_for(user)

          expect(pool_team.current_team.pluck(:league_player_id)).to match_array([skater1.id, skater4.id])
      end
    end
  end
end
