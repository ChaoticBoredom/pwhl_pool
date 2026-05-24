require "rails_helper"

RSpec.describe "Trade::Requests", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:pool_team) { create(:pool_team, pool: pool, owner: user) }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }

  let!(:box) do
    create(:pool_box, pool: pool, league_player_ids: [skater_a.id, skater_b.id])
  end

  let!(:existing_team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: skater_a,
      pool_box: box,
      added_at: 1.week.ago,
    )
  end

  let(:base_params) do
    { new_player_ids: [skater_b.id] }.to_json
  end

  describe "GET /pool_teams/:pool_team_id/trade_requests" do
    let!(:pending_request) do
      create(:trade_request,
        :add,
        :pending,
        pool_team: pool_team,
        league_player: skater_b,
        pool_box: box,
        requested_by: user,
      )
    end

    let!(:cancelled_request) do
      create(:trade_request,
        :add,
        :cancelled,
        pool_team: pool_team,
        league_player: skater_a,
        pool_box: box,
        requested_by: user,
        decided_by: user,
      )
    end

    subject(:get_index) do
      get "/api/pool_teams/#{pool_team.id}/trade_requests", headers: auth_headers
    end

    it "returns 200" do
      get_index
      expect(response).to have_http_status(:ok)
    end

    it "returns all requests" do
      get_index
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to include(pending_request.id)
      expect(ids).to include(cancelled_request.id)
    end
  end

  describe "POST /pool_teams/:pool_team_id/trade_requests" do
    subject(:post_create) do
      post "/api/pool_teams/#{pool_team.id}/trade_requests",
        params: base_params,
        headers: auth_headers
    end

    context "when not the team owner" do
      let(:other_user) { create(:user) }
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        post_create
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when trading is blocked" do
      before { allow_any_instance_of(Pool).to receive(:trade_policy_result).and_return(:blocked) }

      it "returns 403" do
        post_create
        expect(response).to have_http_status(:forbidden)
      end

      it "returns trades_closed reason" do
        post_create
        expect(response.parsed_body["reason"]).to eq("trades_closed")
      end
    end

    context "when trading is allowed" do
      before { allow_any_instance_of(Pool).to receive(:trade_policy_result).and_return(:allowed) }

      let(:fake_result) do
        Trade::ApplicationService::Result.new(
          added_players: [Trade::ApplicationService::Player.new(id: skater_b.id, name: skater_b.name)],
          dropped_players: [Trade::ApplicationService::Player.new(id: skater_a.id, name: skater_a.name)],
        )
      end

      before(:each) do
        allow(Trade::ApplicationService).to receive(:new).and_return(
          instance_double(Trade::ApplicationService, call: fake_result)
        )
      end

      it "returns 200" do
        post_create
        expect(response).to have_http_status(:ok)
      end

      it "calls Trade::ApplicationService" do
        expect(Trade::ApplicationService).to receive(:new).with(
          pool_team,
          adding: [skater_b.id],
          dropping: [skater_a.id],
        ).and_return(instance_double(Trade::ApplicationService, call: fake_result))
        post_create
      end
    end

    context "when trading requires approval" do
      before { allow_any_instance_of(Pool).to receive(:trade_policy_result).and_return(:pending_approval) }

      context "with no conflicst" do
        it "returns 201" do
          post_create
          expect(response).to have_http_status(:created)
        end

        it "returns pending_approval true" do
          post_create
          expect(response.parsed_body["pending_approval"]).to eq(true)
        end

        it "returns a request_group_id" do
          post_create
          expect(response.parsed_body["request_group_id"]).to be_a(String)
        end

        it "creates trade requests" do
          expect { post_create }.to change { Trade::Request.count }.by(2)
        end
      end

      context "with conflicts" do
        let!(:conflicting_request) do
          create(:trade_request,
            :add,
            :pending,
            pool_team: pool_team,
            league_player: skater_b,
            pool_box: box,
            requested_by: user,
          )
        end

        context "with no confirm_replace" do
          it "returns 409" do
            post_create
            expect(response).to have_http_status(:conflict)
          end

          it "returns the conflicting requests" do
            post_create
            expect(response.parsed_body["conflicts"]).to_not be_empty
          end

          it "does not create new trade requests" do
            expect { post_create }.to_not change { Trade::Request.trade_status_pending.count }
          end
        end

        context "with confirm_replace" do
          subject(:post_create_replacing) do
            post "/api/pool_teams/#{pool_team.id}/trade_requests",
              params: { new_player_ids: [skater_b.id], confirm_replace: true }.to_json,
              headers: auth_headers
          end

          it "returns 201" do
            post_create_replacing
            expect(response).to have_http_status(:created)
          end

          it "cancels the conflicting request" do
            post_create_replacing
            expect(conflicting_request.reload).to be_trade_status_cancelled
          end

          # Checking an absolute value instead of `change_by` because there's
          # already a pending request, to `change_by` would be 1, not 2
          it "creates new trade requests" do
            post_create_replacing
            expect(Trade::Request.trade_status_pending.count).to eq(2)
          end
        end
      end
    end
  end

  describe "DELETE /pool_teams/:pool_team_id/trade_requests/:id" do
    let!(:pending_request) do
      create(:trade_request,
        :add,
        :pending,
        pool_team: pool_team,
        league_player: skater_b,
        pool_box: box,
        requested_by: user,
      )
    end

    subject(:delete_request) do
      delete "/api/pool_teams/#{pool_team.id}/trade_requests/#{pending_request.id}",
        headers: auth_headers
    end

    context "when not the team owner" do
      let(:other_user) { create(:user) }
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        delete_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 204" do
      delete_request
      expect(response).to have_http_status(:no_content)
    end

    it "cancels the trade request" do
      delete_request
      expect(pending_request.reload).to be_trade_status_cancelled
    end

    context "when the request is not pending" do
      [:cancelled, :approved].each do |status|
        it "returns 404" do
          pending_request.decide!(status, decided_by: user, decided_at: Time.current)
          delete_request
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
