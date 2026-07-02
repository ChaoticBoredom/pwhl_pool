require "rails_helper"

RSpec.describe "trade decisions", type: :request do
  include_context "pwhl pool"

  let(:auth_headers) { auth_headers_for(admin) }

  let(:skater_2) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "F") }
  let!(:bench_box) { create(:pool_box, pool: pool, name: "Bench Box", league_player_ids: [skater_2.id]) }

  let(:group_id) { SecureRandom.uuid }

  let!(:pending_drop) do
    create(:trade_request,
      :drop,
      :pending,
      pool_team: pool_team,
      league_player: skater,
      pool_box: skater_box,
      requested_by: owner,
      request_group_id: group_id,
    )
  end

  let!(:pending_add) do
    create(:trade_request,
      :add,
      :pending,
      pool_team: pool_team,
      league_player: skater_2,
      pool_box: bench_box,
      requested_by: owner,
      request_group_id: group_id,
    )
  end

  let(:base_url) { "/api/commissioner/#{pool.id}/trade_requests" }

  around(:each) do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe "approving a drop/add pair" do
    subject(:approve) do
      patch base_url,
        params: { ids: [pending_drop.id, pending_add.id], status: "approved" }.to_json,
        headers: auth_headers
    end

    it "returns 200" do
      approve
      expect(response).to have_http_status(:ok)
    end

    it "marks both requests approved" do
      approve
      expect(pending_drop.reload).to be_trade_status_approved
      expect(pending_add.reload).to be_trade_status_approved
    end

    it "drops the player from the roster via the worker" do
      approve
      expect(team_player.reload.dropped_at).to_not be_nil
    end

    it "adds the new player to the roster via the worker" do
      approve
      new_team_player = Pool::TeamPlayer.find_by(pool_team: pool_team, league_player: skater_2)
      expect(new_team_player).to_not be_nil
      expect(new_team_player.dropped_at).to be_nil
      expect(new_team_player.pool_box).to eq(bench_box)
    end
  end

  describe "approving with an invalid backdated_to" do
    subject(:approve_bad_backdate) do
      patch base_url,
        params: { ids: [pending_drop.id, pending_add.id], status: "approved", backdated_to: 2.months.ago.iso8601 }.to_json,
        headers: auth_headers
    end

    it "returns 422" do
      approve_bad_backdate
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not decide the requests" do
      approve_bad_backdate
      expect(pending_drop.reload).to be_trade_status_pending
      expect(pending_add.reload).to be_trade_status_pending
    end

    it "does not touch the roster" do
      approve_bad_backdate
      expect(team_player.reload.dropped_at).to be_nil
      expect(Pool::TeamPlayer.find_by(pool_team: pool_team, league_player: skater_2)).to be_nil
    end
  end

  describe "rejecting a request" do
    subject(:reject) do
      patch base_url,
        params: { ids: [pending_add.id], status: "rejected", rejected_reason: "Not needed" }.to_json,
        headers: auth_headers
    end

    it "returns 200" do
      reject
      expect(response).to have_http_status(:ok)
    end

    it "marks the request rejected without touching the roster" do
      reject
      expect(pending_add.reload).to be_trade_status_rejected
      expect(Pool::TeamPlayer.find_by(pool_team: pool_team, league_player: skater_2)).to be_nil
    end
  end
end
