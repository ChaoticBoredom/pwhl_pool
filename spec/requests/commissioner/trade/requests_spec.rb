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

  let(:base_url) { "/api/commissioner/#{pool.id}/trade_requests" }

  describe "GET /commissioner/:pool_id/trade_requests" do
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

    describe "max_backdate" do
      let!(:active_team_player) do
        create(:pool_team_player,
          pool_team: pool_team,
          league_player: skater_a,
          added_at: added_at,
          dropped_at: nil,
        )
      end
      let(:added_at) { 3.days.ago }

      let!(:pending_drop) do
        create(:trade_request,
          :drop,
          :pending,
          pool_team: pool_team,
          league_player: skater_a,
          pool_box: box,
          requested_by: owner,
          request_group_id: group_id,
        )
      end

      it "includes max_backdate on drop requests for currently active players" do
        get_index
        drop_json = response.parsed_body.find { |r| r["id"] == pending_drop.id }
        expect(Time.zone.parse(drop_json["max_backdate"])).to be_within(1.second).of(added_at)
      end

      it "omits max_backdate on add requests" do
        get_index
        add_json = response.parsed_body.find { |r| r["id"] == pending_add.id }
        expect(add_json).to_not have_key("max_backdate")
      end

      it "omits max_backdate on drop requests for players with no current roster entry" do
        active_team_player.update!(dropped_at: 1.hour.ago)
        get_index
        drop_json = response.parsed_body.find { |r| r["id"] == pending_drop.id }
        expect(drop_json).to have_key("max_backdate")
        expect(drop_json["max_backdate"]).to be_nil
      end
    end
  end

  describe "PATCH /commissioner/:pool_id/trade_requests" do
    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        patch base_url,
          params: { status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when an id is not found" do
      it "returns 404" do
        patch base_url,
          params: { ids: [SecureRandom.uuid], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when an id is not pending" do
      it "returns 404" do
        pending_add.decide!(:cancelled, decided_by: owner, decided_at: Time.current)
        patch base_url,
          params: { ids: [pending_add.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when an id belongs to a different pool" do
      let(:other_pool) { create(:pool, league: league) }
      let(:other_team) { create(:pool_team, pool: other_pool) }
      let!(:other_request) do
        create(:trade_request,
          :add,
          :pending,
          pool_team: other_team,
          league_player: skater_b,
          pool_box: box,
          requested_by: other_team.owner,
        )
      end

      it "returns 404" do
        patch base_url,
          params: { ids: [other_request.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when passed duplicate ids" do
      it "returns 404" do
        patch base_url,
          params: { ids: [pending_add.id, pending_add.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an invalid status" do
      it "returns 422" do
        patch base_url,
          params: { ids: [pending_add.id], status: "banana" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the service succeeds" do
      before(:each) do
        allow(Trade::RequestDecisionService).to receive(:new).and_return(
          instance_double(Trade::RequestDecisionService, call: nil)
        )
      end

      it "returns 200" do
        patch base_url,
          params: { ids: [pending_add.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it "calls Trade::RequestDecisionService with the loaded requests and params" do
        expect(Trade::RequestDecisionService).to receive(:new).with(
          match_array([pending_add]),
          status: "approved",
          decided_by: admin,
          backdated_to: "2026-06-01T00:00:00Z",
          rejected_reason: nil,
        ).and_return(instance_double(Trade::RequestDecisionService, call: nil))

        patch base_url,
          params: { ids: [pending_add.id], status: "approved", backdated_to: "2026-06-01T00:00:00Z" }.to_json,
          headers: auth_headers
      end

      it "passes rejected_reason through for rejections" do
        expect(Trade::RequestDecisionService).to receive(:new).with(
          match_array([pending_add]),
          status: "rejected",
          decided_by: admin,
          backdated_to: nil,
          rejected_reason: "Too Late",
        ).and_return(instance_double(Trade::RequestDecisionService, call: nil))

        patch base_url,
          params: { ids: [pending_add.id], status: "rejected", rejected_reason: "Too Late" }.to_json,
          headers: auth_headers
      end
    end

    context "when the service raises RequestDecisionError" do
      let(:decision_service) { instance_double(Trade::RequestDecisionService) }

      before(:each) do
        allow(Trade::RequestDecisionService).to receive(:new).and_return(decision_service)
        allow(decision_service).to receive(:call).
          and_raise(Trade::RequestDecisionService::RequestDecisionError, "Cannot backdate to 2026-05-01 — invalid for: Skater B")
      end

      it "returns 422" do
        patch base_url,
          params: { ids: [pending_add.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "surfaces the service's error message" do
        patch base_url,
          params: { ids: [pending_add.id], status: "approved" }.to_json,
          headers: auth_headers
        expect(response.parsed_body["error"]).to eq("Cannot backdate to 2026-05-01 — invalid for: Skater B")
      end
    end
  end
end
