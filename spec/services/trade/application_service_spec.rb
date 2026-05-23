require "rails_helper"

RSpec.describe Trade::ApplicationService do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }
  let(:owner) { create(:user) }
  let(:pool_team) { create(:pool_team, pool: pool, owner: owner) }

  let(:skater_a) { create(:pwhl_skater, league: league) }
  let(:skater_b) { create(:pwhl_skater, league: league) }
  let(:skater_c) { create(:pwhl_skater, league: league) }
  let(:skater_d) { create(:pwhl_skater, league: league) }

  let!(:box) do
    create(:pool_box, pool: pool, league_player_ids: [skater_a.id, skater_b.id, skater_c.id])
  end

  let!(:existing_team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: skater_a,
      pool_box: box,
      added_at: 1.week.ago,
    )
  end

  def call_service(adding: [], dropping: [], backdated_to: nil)
    described_class.new(
      pool_team,
      adding: adding,
      dropping: dropping,
      backdated_to: backdated_to,
    ).call
  end

  describe "#call" do
    context "when dropping players" do
      it "stamps dropped_at on the team player" do
        call_service(dropping: [skater_a.id])
        expect(existing_team_player.reload.dropped_at).to be_within(1.second).of(Time.current)
      end

      it "returns the dropped player in the result" do
        result = call_service(dropping: [skater_a.id])
        expect(result.dropped_players.map(&:id)).to include(skater_a.id)
      end

      it "returns the dropped player name in the result" do
        result = call_service(dropping: [skater_a.id])
        expect(result.dropped_players.map(&:name)).to include(skater_a.name)
      end

      it "returns an empty added_players list" do
        result = call_service(dropping: [skater_a.id])
        expect(result.added_players).to be_empty
      end

      context "when player is not on the team" do
        it "does not raise" do
          expect { call_service(dropping: [skater_b.id]) }.to_not raise_error
        end

        it "returns an empty dropped_players list" do
          result = call_service(dropping: [skater_b.id])
          expect(result.dropped_players).to be_empty
        end

        it "does not alter the team" do
          expect {
            call_service(dropping: [skater_b.id])
          }.to_not change { pool_team.pool_team_players.count }
        end
      end
    end

    context "when adding players" do
      it "creates a new pool_team_player" do
        expect {
          call_service(adding: [skater_b.id])
        }.to change { pool_team.pool_team_players.count }.by(1)
      end

      it "sets added_at to now" do
        call_service(adding: [skater_b.id])
        tp = pool_team.pool_team_players.find_by(league_player_id: skater_b.id)
        expect(tp.added_at).to be_within(1.second).of(Time.current)
      end

      it "assigns the correct pool_box" do
        call_service(adding: [skater_b.id])
        tp = pool_team.pool_team_players.find_by(league_player_id: skater_b.id)
        expect(tp.pool_box).to eq(box)
      end

      it "returns the added player in the result" do
        result = call_service(adding: [skater_b.id])
        expect(result.added_players.map(&:id)).to include(skater_b.id)
      end

      it "returns the added player name in the result" do
        result = call_service(adding: [skater_b.id])
        expect(result.added_players.map(&:name)).to include(skater_b.name)
      end

      it "returns an empty dropped_players list" do
        result = call_service(adding: [skater_b.id])
        expect(result.dropped_players).to be_empty
      end

      context "when the player has no active box" do
        let!(:inactive_box) do
          create(:pool_box, pool: pool, league_player_ids: [skater_d.id], active: false)
        end

        it "raises TradeApplicationError" do
          expect {
            call_service(adding: [skater_d.id])
          }.to raise_error(Trade::ApplicationService::ApplicationError, /No active box found/)
        end

        it "rolls back without creating any team players" do
          expect {
            call_service(adding: [skater_d.id]) rescue nil
          }.to_not change { pool_team.pool_team_players.count }
        end
      end
    end

    context "when adding and dropping players" do
      it "drops the outgoing player and adds the incoming player" do
        # Adding and dropping players, count should remain the same
        expect {
          call_service(adding: [skater_b.id], dropping: [skater_a.id])
        }.to_not change { pool_team.reload.current_team.count }
        expect(pool_team.pool_team_players.find_by(league_player_id: skater_b.id)).to be_present
        expect(pool_team.current_team.find_by(league_player_id: skater_a.id)).to_not be_present
      end

      it "returns both added and dropped players in the result" do
        result = call_service(adding: [skater_b.id], dropping: [skater_a.id])
        expect(result.added_players.map(&:id)).to include(skater_b.id)
        expect(result.dropped_players.map(&:id)).to include(skater_a.id)
      end
    end

    context "with backdated_to" do
      let(:backdated_to) { 3.days.ago.beginning_of_day + 6.hours }

      it "uses backdated_to as added_at" do
        call_service(adding: [skater_b.id], backdated_to: backdated_to)
        tp = pool_team.pool_team_players.find_by(league_player_id: skater_b.id)
        expect(tp.added_at).to be_within(1.second).of(backdated_to)
      end

      it "uses backdated_to as dropped_at" do
        call_service(dropping: [skater_a.id], backdated_to: backdated_to)
        expect(existing_team_player.reload.dropped_at).to be_within(1.second).of(backdated_to)
      end
    end

    context "when adding and dropping are both empty" do
      it "returns empty result without raising" do
        result = call_service
        expect(result.added_players).to be_empty
        expect(result.dropped_players).to be_empty
      end

      it "does not change the team player count" do
        expect {
          call_service
        }.to_not change { pool_team.pool_team_players.count }
      end
    end

    context "when a create! fails" do
      before(:each) do
        allow(pool_team.pool_team_players).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises" do
        expect {
          call_service(adding: [skater_b.id])
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "rolls back any drops" do
        expect {
          call_service(adding: [skater_b.id], dropping: [skater_a.id])
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect(existing_team_player.reload.dropped_at).to be_nil
      end
    end

    context "when an update! fails" do
      before do
        allow_any_instance_of(Pool::TeamPlayer).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises" do
        expect {
          call_service(dropping: [skater_a.id])
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "rolls back without creating new team players" do
        expect {
          call_service(adding: [skater_b.id], dropping: [skater_a.id])
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect(pool_team.pool_team_players.find_by(league_player_id: skater_b.id)).to be_nil
      end
    end
  end
end
