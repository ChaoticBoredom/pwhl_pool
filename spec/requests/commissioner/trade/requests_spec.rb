require "rails_helper"

RSpec.describe "Commissioner::Trade::Requests", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:auth_headers) { auth_headers_for(admin) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, admin: admin, league: league) }
  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:owner) { pool_team.owner }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }
  let!(:box) { create(:pool_box, pool: pool, league_player_ids: [skater_a.id, skater_b.id]) }

  let(:group_id) { SecureRandom.uuid }

  let!(:pending_add) do
    create(:trade_request,
      :add,
      :pending,
      pool_team: pool_team,
      league_player: skater_b,
      pool_box: box,
      requested_by: owner,
      request_group_id: group_id,
    )
  end

  let(:base_url) { "/api/commissioner/pools/#{pool.id}/trade_requests" }

  describe "GET /commissioner/pools/:pool_id/trade_requests" do
    let!(:approved_request) do
      create(:trade_request,
        :approved,
        :add,
        pool_team: pool_team,
        league_player: skater_a,
        pool_box: box,
        requested_by: owner,
        decided_by: admin,
      )
    end

    subject(:get_index) { get base_url, headers: auth_headers }

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        get_index
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 200" do
      get_index
      expect(response).to have_http_status(:ok)
    end

    it "returns all trade requests" do
      get_index
      ids = response.parsed_body.map { |r| r["id"] }
      expect(ids).to match_array([pending_add.id, approved_request.id])
    end
  end

  describe "PATCH /commissioner/pools/:pool_id/trade_requests/:id" do
    let(:request_url) { "#{base_url}/#{pending_add.id}" }

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        patch request_url,
          params: { status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when approving" do
      subject(:approve) do
        patch request_url,
          params: { status: "approved" }.to_json,
          headers: auth_headers
      end

      before(:each) { allow(TradeApprovalWorker).to receive(:perform_async) }

      it "returns 200" do
        approve
        expect(response).to have_http_status(:ok)
      end

      it "transitions the request to approved" do
        approve
        expect(pending_add.reload).to be_trade_status_approved
      end

      it "stamps decided_by" do
        approve
        expect(pending_add.reload.decided_by).to eq(admin)
      end

      it "stamps decided_at" do
        approve
        expect(pending_add.reload.decided_at).to be_within(1.second).of(Time.current)
      end

      it "enqueues TradeApprovalWorker" do
        expect(TradeApprovalWorker).to receive(:perform_async).with(group_id)
        approve
      end

      context "with backdated_to" do
        let(:backdated_to) { 3.days.ago.midday }

        it "sets backdated_to on the request" do
          patch request_url,
            params: { status: "approved", backdated_to: backdated_to.iso8601 }.to_json,
            headers: auth_headers
          expect(pending_add.reload.backdated_to).
            to be_within(1.second).of(backdated_to)
        end
      end
    end

    context "when rejecting" do
      subject(:reject) do
        patch request_url,
          params: { status: "rejected", rejected_reason: "Too Late" }.to_json,
          headers: auth_headers
      end

      it "returns 200" do
        reject
        expect(response).to have_http_status(:ok)
      end

      it "transitions the request to rejected" do
        reject
        expect(pending_add.reload).to be_trade_status_rejected
      end

      it "stamps decided_by" do
        reject
        expect(pending_add.reload.decided_by).to eq(admin)
      end

      it "stores the rejected_reason" do
        reject
        expect(pending_add.reload.rejected_reason).to eq("Too Late")
      end
    end

    context "with an invalid status" do
      it "returns 422" do
        patch request_url,
          params: { status: "banana" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the request is not pending" do
      before { pending_add.decide!(:cancelled, decided_by: owner, decided_at: Time.current) }

      it "returns 404" do
        patch request_url,
          params: { status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the request belongs to a different pool" do
      let(:other_pool) { create(:pool, league: league) }
      let(:other_pool_team) { create(:pool_team, pool: other_pool) }
      let!(:other_request) do
        create(:trade_request,
          :add,
          :pending,
          pool_team: other_pool_team,
          league_player: skater_b,
          pool_box: box,
          requested_by: other_pool_team.owner,
        )
      end

      it "returns 404" do
        patch "#{base_url}/#{other_request.id}",
          params: { status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
