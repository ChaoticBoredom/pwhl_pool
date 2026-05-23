require "rails_helper"

RSpec.describe Trade::RequestCreationService do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:owner) { create(:user) }
  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:other_pool_team) { create(:pool_team, pool: pool) }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }
  let(:skater_c) { create(:pwhl_skater, league: league) }
  let(:skater_d) { create(:pwhl_skater, league: league) }

  let!(:box) do
    create(:pool_box,
      pool: pool,
      league_player_ids: [skater_a.id, skater_b.id, skater_c.id]
    )
  end

  let!(:inactive_box) do
    create(:pool_box,
      pool: pool,
      league_player_ids: [skater_a.id, skater_d.id],
      active: false
    )
  end

  let!(:existing_team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: skater_a,
      pool_box: box,
      added_at: 1.week.ago,
    )
  end

  def build_service(adding: [], dropping: [])
    described_class.new(pool_team, owner, adding: adding, dropping: dropping)
  end

  describe "#conflicts" do
    context "when there are pending requests for the same players and actions" do
      let!(:pending_add) do
        create(:trade_request,
          :add,
          :pending,
          pool_team: pool_team,
          pool_box: box,
          league_player: skater_b,
          requested_by: owner,
        )
      end

      it "returns the conflicting pending add request" do
        expect(build_service(adding: [skater_b.id]).conflicts).to include(pending_add)
      end

      it "does returns requests for different actions" do
        expect(build_service(dropping: [skater_b.id]).conflicts).to include(pending_add)
      end

      it "does not return requests for different players" do
        expect(build_service(adding: [skater_c.id]).conflicts).to be_empty
      end

      it "does not return non-pending requests" do
        pending_add.decide!(:cancelled, decided_by: owner, decided_at: Time.current)
        expect(build_service(adding: [skater_b.id]).conflicts).to be_empty
      end

      it "does not return requests for other pool teams" do
        other_request = create(:trade_request,
          :add,
          :pending,
          pool_team: other_pool_team,
          pool_box: box,
          league_player: skater_b,
          requested_by: owner,
        )
        expect(build_service(adding: [skater_b.id]).conflicts).to_not include(other_request)
      end
    end

    context "when there are no pending requests" do
      it "returns an empty collection" do
        expect(build_service(adding: [skater_b.id]).conflicts).to be_empty
      end
    end
  end

  describe "#call" do
    it "creates a drop request for each dropping player" do
      expect {
        build_service(dropping: [skater_a.id]).call
      }.to change { Trade::Request.trade_action_drop.count }.by(1)
    end

    it "creates an add request for each adding player" do
      expect {
        build_service(adding: [skater_b.id]).call
      }.to change { Trade::Request.trade_action_add.count }.by(1)
    end

    it "assigns the same request_group_id to all requests" do
      build_service(adding: [skater_b.id], dropping: [skater_a.id]).call
      group_ids = Trade::Request.last(2).map(&:request_group_id).uniq
      expect(group_ids.length).to eq(1)
    end

    it "returns the request_group_id" do
      group_id = build_service(adding: [skater_b.id]).call
      expect(group_id).to eq(Trade::Request.last.request_group_id)
    end

    it "sets 'requested_by' on each request" do
      build_service(adding: [skater_b.id]).call
      expect(Trade::Request.last.requested_by).to eq(owner)
    end

    context "when adding players" do
      it "assigns the correct 'pool_box'" do
        build_service(adding: [skater_b.id]).call
        expect(Trade::Request.last.pool_box).to eq(box)
      end

      it "raises RequestCreationError when player has no active box" do
        expect {
          build_service(adding: [skater_d.id]).call
        }.to raise_error(
          Trade::RequestCreationService::RequestCreationError,
          /No active box found/
        )
      end
    end

    it "raises RequestCreationError on duplicate pending request" do
      create(:trade_request,
        :add,
        :pending,
        pool_team: pool_team,
        league_player: skater_b,
        requested_by: owner
      )

      expect {
        build_service(adding: [skater_b.id]).call
      }.to raise_error(Trade::RequestCreationService::RequestCreationError)
    end

    it "rolls back all requests on failure" do
      expect {
        build_service(adding: [skater_d.id], dropping: [skater_a.id]).call rescue nil
      }.to_not change { Trade::Request.count }
    end
  end

  describe "#call_replacing_conflicts" do
    let!(:pending_add) do
      create(:trade_request,
        :add,
        :pending,
        pool_team: pool_team,
        pool_box: box,
        league_player: skater_b,
        requested_by: owner,
      )
    end

    let(:service) { build_service(adding: [skater_b.id]) }

    it "cancels conflicting pending requests" do
      service.call_replacing_conflicts
      expect(pending_add.reload).to be_trade_status_cancelled
    end

    it "stamps 'decided_at' on cancelled requests" do
      service.call_replacing_conflicts
      expect(pending_add.reload.decided_by).to eq(owner)
    end

    it "creates new requests after cancelling conficts" do
      expect {
        service.call_replacing_conflicts
      }.to_not change { Trade::Request.trade_status_pending.count }
    end

    it "returns a 'request_group_id'" do
      group_id = service.call_replacing_conflicts
      expect(group_id).to be_a(String)
    end

    it "rolls back if request creation fails" do
      bad_service = build_service(adding: [skater_d.id])

      expect {
        bad_service.call_replacing_conflicts rescue nil
      }.to_not change { pending_add.reload.status }
    end
  end
end
