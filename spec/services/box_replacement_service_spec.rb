require "rails_helper"

RSpec.describe BoxReplacementService do
  let(:admin) { create(:user) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league, admin: admin, state: :draft) }
  let(:players) { create_list(:pwhl_skater, 3, league: league) }

  let(:boxes_data) do
    [
      {
        name: "Forwards Box 1",
        position: 1,
        players: [{ id: players[0].id }, { id: players[1].id }],
      },
      {
        name: "Defence Box 1",
        position: 2,
        players: [{ id: players[2].id }],
      },
    ]
  end

  subject(:service) { described_class.new(pool, boxes_data) }

  describe "#call" do
    context "when pool is in draft state" do
      it "returns a successful result" do
        expect(service.call.success).to be(true)
      end

      it "returns no errors" do
        expect(service.call.errors).to be_empty
      end

      it "creates the boxes" do
        expect { service.call }.to change { pool.pool_boxes.count }.by(2)
      end

      it "destroys existing boxes" do
        existing = create(:pool_box, pool: pool)

        service.call

        expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "sets box names correctly" do
        service.call

        expect(pool.pool_boxes.active.order(:position).pluck(:name)).to eq(
          ["Forwards Box 1", "Defence Box 1"]
        )
      end

      it "assigns player ids to boxes" do
        service.call

        box = pool.pool_boxes.active.find_by(name: "Forwards Box 1")
        expect(box.league_player_ids).to match_array([players[0].id, players[1].id])
      end

      it "sets all new boxes as active" do
        service.call

        expect(pool.pool_boxes.active.count).to eq(2)
      end

      context "when a box is invalid" do
        let(:boxes_data) do
          [{ name: nil, position: 1, players: [] }]
        end

        it "returns a failed result" do
          expect(service.call.success).to be(false)
        end

        it "returns errors" do
          expect(service.call.errors).to be_present
        end

        it "does not create any boxes" do
          expect { service.call }.to_not change { pool.pool_boxes.count }
        end

        it "does not destroy existing boxes" do
          existing = create(:pool_box, pool: pool)

          service.call

          expect { existing.reload }.to_not raise_error
        end
      end
    end

    context "when pool is active" do
      let(:pool) { create(:pool, league: league, admin: admin, state: :active) }
      let(:pool_team) { create(:pool_team, pool: pool) }
      let(:old_box) { create(:pool_box, pool: pool, active: true) }

      it "returns a successful result" do
        expect(service.call.success).to be(true)
      end

      it "deactivates existing boxes" do
        old_box

        service.call

        expect(old_box.reload.active).to be(false)
      end

      it "creates new active boxes" do
        service.call

        expect(pool.pool_boxes.active.count).to eq(2)
      end

      it "does not destroy existing boxes" do
        old_box

        service.call

        expect { old_box.reload }.to_not raise_error
      end

      it "force drops active team players" do
        active_player = create(:pool_team_player,
          pool_team: pool_team,
          league_player: players[0],
          dropped_at: nil,
        )

        service.call

        expect(active_player.reload.dropped_at).to be_within(2.seconds).of(Time.current)
      end

      it "does not touch already dropped players" do
        dropped_at = 2.days.ago
        already_dropped = create(:pool_team_player,
          pool_team: pool_team,
          league_player: players[1],
          dropped_at: dropped_at,
        )

        service.call

        expect(already_dropped.reload.dropped_at).to be_within(1.second).of(dropped_at)
      end

      context "when a box is invalid" do
        let(:boxes_data) do
          [{ name: nil, position: 1, players: [] }]
        end

        it "returns a failed result" do
          expect(service.call.success).to be(false)
        end

        it "does not deactivate existing boxes" do
          old_box

          service.call

          expect(old_box.reload.active).to be(true)
        end

        it "does not drop any players" do
          active_player = create(:pool_team_player,
            pool_team: pool_team,
            league_player: players[0],
            dropped_at: nil,
          )

          service.call

          expect(active_player.reload.dropped_at).to be_nil
        end
      end
    end

    context "when pool is completed" do
      let(:pool) { create(:pool, admin: admin, state: :completed) }

      it "returns a failed result" do
        expect(service.call.success).to be(false)
      end

      it "returns an error mentioning the pool state" do
        expect(service.call.errors.join).to match(/completed/)
      end

      it "does not create any boxes" do
        expect { service.call }.to_not change { pool.pool_boxes.count }
      end
    end
  end
end
