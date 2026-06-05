require "rails_helper"

RSpec.describe "Trade::Requests", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:pool_team) { create(:pool_team, pool: pool, owner: user) }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }
  let(:skater_c) { create(:pwhl_skater, league: league) }

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

      context "with no conflicts" do
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

          it "creates new trade requests" do
            post_create_replacing
            expect(Trade::Request.trade_status_pending.count).to eq(2)
          end
        end
      end
    end
  end

  describe "POST /pool_teams/:pool_team_id/trade_requests/cancel" do
    let(:group_id) { SecureRandom.uuid }

    let!(:pending_add) do
      create(:trade_request,
        :add,
        :pending,
        pool_team: pool_team,
        league_player: skater_b,
        pool_box: box,
        requested_by: user,
        request_group_id: group_id,
      )
    end

    let!(:pending_drop) do
      create(:trade_request,
        :drop,
        :pending,
        pool_team: pool_team,
        league_player: skater_a,
        pool_box: box,
        requested_by: user,
        request_group_id: group_id,
      )
    end

    subject(:post_cancel) do
      post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
        params: { id: pending_add.id }.to_json,
        headers: auth_headers
    end

    context "when not the team owner" do
      let(:other_user) { create(:user) }

      it "returns 403" do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: { id: pending_add.id }.to_json,
          headers: auth_headers_for(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with no scope param" do
      it "returns 400" do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: {}.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an informative error message" do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: {}.to_json,
          headers: auth_headers
        expect(response.parsed_body["error"]).to include("One of", "id", "pool_box_id", "request_group_id")
      end
    end

    context "with multiple scope params" do
      it "returns 400" do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: { id: pending_add.id, pool_box_id: box.id }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an informative error message" do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: { id: pending_add.id, pool_box_id: box.id }.to_json,
          headers: auth_headers
        expect(response.parsed_body["error"]).to include("Only one of")
      end
    end

    context "by id" do
      it "returns 204" do
        post_cancel
        expect(response).to have_http_status(:no_content)
      end

      it "cancels only the specified request" do
        post_cancel
        expect(pending_add.reload).to be_trade_status_cancelled
        expect(pending_drop.reload).to be_trade_status_pending
      end

      it "returns 404 when request is not pending" do
        pending_add.decide!(:cancelled, decided_by: user, decided_at: Time.current)
        post_cancel
        expect(response).to have_http_status(:not_found)
      end
    end

    context "by pool_box_id" do
      subject(:post_cancel_by_box) do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: { pool_box_id: box.id }.to_json,
          headers: auth_headers
      end

      it "returns 204" do
        post_cancel_by_box
        expect(response).to have_http_status(:no_content)
      end

      it "cancels all pending requests for the box" do
        post_cancel_by_box
        expect(pending_add.reload).to be_trade_status_cancelled
        expect(pending_drop.reload).to be_trade_status_cancelled
      end

      it "does not cancel requests for other boxes" do
        other_box = create(:pool_box, pool: pool, league_player_ids: [skater_c.id])
        other_request = create(:trade_request,
          :add,
          :pending,
          pool_team: pool_team,
          league_player: skater_c,
          pool_box: other_box,
          requested_by: user,
        )
        post_cancel_by_box
        expect(other_request.reload).to be_trade_status_pending
      end
    end

    context "by request_group_id" do
      subject(:post_cancel_by_group) do
        post "/api/pool_teams/#{pool_team.id}/trade_requests/cancel",
          params: { request_group_id: group_id }.to_json,
          headers: auth_headers
      end

      it "returns 204" do
        post_cancel_by_group
        expect(response).to have_http_status(:no_content)
      end

      it "cancels all requests in the group" do
        post_cancel_by_group
        expect(pending_add.reload).to be_trade_status_cancelled
        expect(pending_drop.reload).to be_trade_status_cancelled
      end

      it "does not cancel requests from other groups" do
        other_request = create(:trade_request,
          :add,
          :pending,
          pool_team: pool_team,
          league_player: skater_c,
          pool_box: box,
          requested_by: user,
          request_group_id: SecureRandom.uuid,
        )
        post_cancel_by_group
        expect(other_request.reload).to be_trade_status_pending
      end
    end
  end
end
