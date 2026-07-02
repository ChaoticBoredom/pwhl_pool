require "rails_helper"

RSpec.describe Trade::RequestDecisionService do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:admin) { pool.admin }
  let(:pool_team) { create(:pool_team, pool: pool) }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }
  let(:skater_c) { create(:pwhl_skater, league: league) }

  let!(:box) do
    create(:pool_box, pool: pool, league_player_ids: [skater_a.id, skater_b.id, skater_c.id])
  end

  let(:group_id) { SecureRandom.uuid }

  def build_service(requests, status:, backdated_to: nil, rejected_reason: nil)
    described_class.new(
      requests,
      status: status,
      decided_by: admin,
      backdated_to: backdated_to,
      rejected_reason: rejected_reason,
    )
  end

  describe "#call" do
    context "when approving" do
      before(:each) { allow(TradeApprovalWorker).to receive(:perform_async) }

      let!(:pending_add) do
        create(:trade_request,
          :add,
          :pending,
          pool_team: pool_team,
          league_player: skater_b,
          pool_box: box,
          requested_by: pool_team.owner,
          request_group_id: group_id,
        )
      end

      subject(:approve) { build_service([pending_add], status: "approved").call }

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

      it "assigns a new request_group_id" do
        approve
        expect(pending_add.reload.request_group_id).to_not eq(group_id)
      end

      it "enqueues the worker with the new request_group_id" do
        approve
        new_group_id = pending_add.reload.request_group_id
        expect(TradeApprovalWorker).to have_received(:perform_async).with(new_group_id)
      end

      context "with backdated_to" do
        let(:backdated_to) { 3.days.ago.midday }

        it "sets backdated_to on the request" do
          build_service([pending_add], status: "approved", backdated_to: backdated_to.iso8601).call
          expect(pending_add.reload.backdated_to).to be_within(1.second).of(backdated_to)
        end
      end

      context "when approving a sub-group from a larger group" do
        let!(:pending_drop) do
          create(:trade_request,
            :drop,
            :pending,
            pool_team: pool_team,
            league_player: skater_a,
            pool_box: box,
            requested_by: pool_team.owner,
            request_group_id: group_id,
          )
        end

        before { allow(TradeApprovalWorker).to receive(:perform_async) }

        it "breaks the approved request into its own group" do
          build_service([pending_add], status: "approved").call
          expect(pending_add.reload.request_group_id).to_not eq(pending_drop.request_group_id)
        end

        it "leaves the other request in the original group" do
          build_service([pending_add], status: "approved").call
          expect(pending_drop.reload.request_group_id).to eq(group_id)
        end
      end

      context "when approving across multiple original groups" do
        let(:other_group_id) { SecureRandom.uuid }

        let!(:other_pending) do
          create(:trade_request,
            :add,
            :pending,
            pool_team: pool_team,
            league_player: skater_a,
            pool_box: box,
            requested_by: pool_team.owner,
            request_group_id: other_group_id,
          )
        end

        before { allow(TradeApprovalWorker).to receive(:perform_async) }

        it "preserves original group_ids" do
          build_service([pending_add, other_pending], status: "approved").call
          expect(pending_add.reload.request_group_id).to eq(group_id)
          expect(other_pending.reload.request_group_id).to eq(other_group_id)
        end

        it "enqueues a worker for each group id" do
          build_service([pending_add, other_pending], status: "approved").call
          expect(TradeApprovalWorker).to have_received(:perform_async).with(group_id)
          expect(TradeApprovalWorker).to have_received(:perform_async).with(other_group_id)
        end
      end

      context "backdate validation against a dropped player's added_at" do
        let!(:pending_drop) do
          create(:trade_request,
            :drop,
            :pending,
            pool_team: pool_team,
            league_player: skater_a,
            pool_box: box,
            requested_by: pool_team.owner,
          )
        end

        let!(:active_team_player) do
          create(:pool_team_player,
            pool_team: pool_team,
            league_player: skater_a,
            added_at: added_at,
            dropped_at: nil,
          )
        end
        let(:added_at) { 3.days.ago }

        it "does not raise when backdated_to is on or after added_at" do
          expect {
            build_service([pending_drop], status: "approved", backdated_to: added_at.iso8601).call
          }.to_not raise_error
        end

        it "raises when backdated_to predates added_at" do
          expect {
            build_service([pending_drop], status: "approved", backdated_to: 4.days.ago.iso8601).call
          }.to raise_error(described_class::RequestDecisionError, /#{skater_a.name}/)
        end

        it "does not raise for add-only requests regardless of backdated_to" do
          add_request = create(:trade_request,
            :add,
            :pending,
            pool_team: pool_team,
            league_player: skater_c,
            pool_box: box,
            requested_by: pool_team.owner,
          )

          expect {
            build_service([add_request], status: "approved", backdated_to: 10.days.ago.iso8601).call
          }.to_not raise_error
        end

        it "does not raise when the dropped player has no current roster entry" do
          active_team_player.update!(dropped_at: 1.hour.ago)

          expect {
            build_service([pending_drop], status: "approved", backdated_to: 4.days.ago.iso8601).call
          }.to_not raise_error
        end

        it "includes every violating player in a single error message" do
          other_drop = create(:trade_request,
            :drop,
            :pending,
            pool_team: pool_team,
            league_player: skater_c,
            pool_box: box,
            requested_by: pool_team.owner,
          )
          create(:pool_team_player,
            pool_team: pool_team,
            league_player: skater_c,
            added_at: 2.days.ago,
            dropped_at: nil,
          )

          expect {
            build_service([pending_drop, other_drop], status: "approved", backdated_to: 4.days.ago.iso8601).call
          }.to raise_error(described_class::RequestDecisionError) { |e|
            expect(e.message).to match(/#{skater_a.name}/)
            expect(e.message).to match(/#{skater_c.name}/)
          }
        end
      end
    end

    context "when rejecting" do
      let!(:pending_add) do
        create(:trade_request,
          :add,
          :pending,
          pool_team: pool_team,
          league_player: skater_b,
          pool_box: box,
          requested_by: pool_team.owner,
          request_group_id: group_id,
        )
      end

      subject(:reject) { build_service([pending_add], status: "rejected", rejected_reason: "Too Late").call }

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

      it "raises when rejected_reason is blank" do
        expect {
          build_service([pending_add], status: "rejected", rejected_reason: "").call
        }.to raise_error(described_class::RequestDecisionError, /reason/i)
      end

      it "ignores backdated_to entirely" do
        expect {
          build_service([pending_add], status: "rejected", rejected_reason: "Too Late", backdated_to: 100.years.ago.iso8601).call
        }.to_not raise_error
      end

      context "when rejecting a sub-group from a larger group" do
        let!(:pending_drop) do
          create(:trade_request,
            :drop,
            :pending,
            pool_team: pool_team,
            league_player: skater_a,
            pool_box: box,
            requested_by: pool_team.owner,
            request_group_id: group_id,
          )
        end

        it "breaks the rejected request into its own group" do
          build_service([pending_add], status: "rejected", rejected_reason: "Too Late").call
          expect(pending_add.reload.request_group_id).to_not eq(pending_drop.request_group_id)
        end

        it "leaves the other request in the original group" do
          build_service([pending_add], status: "rejected", rejected_reason: "Too Late").call
          expect(pending_drop.reload.request_group_id).to eq(group_id)
        end
      end
    end
  end
end
