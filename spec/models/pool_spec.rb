require "rails_helper"

RSpec.describe Pool, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:pool_type) }

  let(:season_id) { "current" }
  let(:reference_season_id) { "previous" }
  let(:league) { create(:league) }

  subject { create(:pool, league: league, season_id: season_id) }

  context "validates that 'season_id' and 'reference_season_id' differ from each other" do
    subject { build(:pool, league: league, season_id: season_id, reference_season_id: season_id) }

    it "raises a validation error when they are the same" do
      expect(subject).to_not be_valid
    end

    it "has a meaningful error message" do
      subject.valid?
      expect(subject.errors[:reference_season_id]).to include("must differ from season_id")
    end
  end

  describe "#display_season_id" do
    context "when 'reference_season_id' is present" do
      it "returns reference_season_id" do
        subject.reference_season_id = reference_season_id
        expect(subject.display_season_id).to eq(reference_season_id)
      end
    end

    context "when 'reference_season_id' is nil" do
      it "returns season_id" do
        expect(subject.display_season_id).to eq(season_id)
      end
    end
  end

  describe "#using_reference_season?" do
    context "when 'reference_season_id' is present" do
      it "returns truthy" do
        subject.reference_season_id = reference_season_id
        expect(subject.using_reference_season?).to eq(true)
      end
    end

    context "when 'reference_season_id' is nil" do
      it "returns season_id" do
        expect(subject.using_reference_season?).to eq(false)
      end
    end
  end

  describe "#start_end_range" do
    context "when league has games in given season" do
      let!(:first_game) { create(:league_game, :final, league: league, season_id: season_id) }
      let!(:last_game) { create(:league_game, :scheduled, league: league, season_id: season_id) }

      it "returns first and last start_times as the range" do
        expected_range = first_game.start_time.beginning_of_day..last_game.start_time.end_of_day
        expect(subject.start_end_range).to eq(expected_range)
      end
    end

    context "when league has no games in given season" do
      let!(:first_game) { create(:league_game, :final, league: league, season_id: "2024") }
      let!(:last_game) { create(:league_game, :scheduled, league: league, season_id: "2023") }

      it "returns a range based on itself" do
        subject.save
        expect(subject.start_end_range.begin).to eq(subject.created_at.beginning_of_day)
        expect(subject.start_end_range.end).to be_within(5.seconds).of(1.year.from_now.end_of_day)
      end
    end

    context "when league has no games" do
      it "returns a range based on itself" do
        subject.save
        expect(subject.start_end_range.begin).to eq(subject.created_at.beginning_of_day)
        expect(subject.start_end_range.end).to be_within(5.seconds).of(1.year.from_now.end_of_day)
      end

      it "calls the cache with a 1 hour TTL" do
        expect(Rails.cache).to receive(:fetch).
          with(anything, hash_including(expires_in: 1.hour)).
          and_call_original
        subject.start_end_range
      end
    end
  end

  describe "#active_box_by_player_id" do
    let(:player_a) { create(:pwhl_skater, league: league) }
    let(:player_b) { create(:pwhl_skater, league: league) }
    let(:player_c) { create(:pwhl_skater, league: league) }

    let!(:active_box) { create(:pool_box, pool: subject, league_player_ids: [player_a.id, player_b.id]) }
    let!(:inactive_box) { create(:pool_box, pool: subject, league_player_ids: [player_c.id], active: false) }

    it "maps active box players to their box" do
      expect(subject.active_box_by_player_id[player_a.id]).to eq(active_box)
    end

    it "maps all players in an active box" do
      expect(subject.active_box_by_player_id[player_b.id]).to eq(active_box)
    end

    it "excludes players in inactive boxes" do
      expect(subject.active_box_by_player_id[player_c.id]).to be_nil
    end
  end

  describe "#trading_allowed?" do
    it "returns true when trade_policy_result is :allowed" do
      allow(subject).to receive(:trade_policy_result).and_return(:allowed)
      expect(subject.trading_allowed?).to eq(true)
    end

    it "returns false otherwise" do
      allow(subject).to receive(:trade_policy_result).and_return(:pending_approval)
      expect(subject.trading_allowed?).to eq(false)
    end
  end

  describe "#trading_allowed_pending_approval?" do
    it "returns true when trade_policy_result is :pending_approval" do
      allow(subject).to receive(:trade_policy_result).and_return(:pending_approval)
      expect(subject.trading_allowed_pending_approval?).to eq(true)
    end

    it "returns false otherwise" do
      allow(subject).to receive(:trade_policy_result).and_return(:blocked)
      expect(subject.trading_allowed_pending_approval?).to eq(false)
    end
  end

  describe "#trading_blocked?" do
    it "returns true when trade_policy_result is :blocked" do
      allow(subject).to receive(:trade_policy_result).and_return(:blocked)
      expect(subject.trading_blocked?).to eq(true)
    end

    it "returns false otherwise" do
      allow(subject).to receive(:trade_policy_result).and_return(:allowed)
      expect(subject.trading_blocked?).to eq(false)
    end
  end

  describe "#trade_policy_result" do
    context "when the pool is not active" do
      [
        [:draft, :blocked],
        [:completed, :blocked],
      ].each do |state, expected|
        it "returns #{expected} for pool_state #{state}" do
          subject.update(state: state)
          allow(league).to receive(:games_started?).and_return(false)
          expect(subject.trade_policy_result).to eq(expected)
        end
      end
    end

    context "when a league game has started" do
      before { allow(league).to receive(:games_started?).and_return(true) }

      [
        :disabled,
        :open,
        :approval_required,
        :windowed,
        :windowed_overflow,
      ].each do |policy|
        it "returns :blocked for #{policy}" do
          subject.update(trade_policy: policy)
          expect(subject.trade_policy_result).to eq(:blocked)
        end
      end
    end

    context "when no league games have started" do
      before { allow(league).to receive(:games_started?).and_return(false) }

      [
        [:disabled, :blocked],
        [:open, :allowed],
        [:approval_required, :pending_approval],
      ].each do |policy, expected|
        it "returns #{expected} for #{policy}" do
          subject.update(trade_policy: policy)
          expect(subject.trade_policy_result).to eq(expected)
        end
      end

      [
        [:windowed, :allowed, :blocked],
        [:windowed_overflow, :allowed, :pending_approval],
      ].each do |policy, in_window_result, out_of_window_result|
        context "with #{policy}" do
          before(:each) { subject.update(trade_policy: policy) }

          context "with a trade window" do
            it "returns #{in_window_result} when inside a trade window" do
              allow(subject.trade_windows).to receive(:current).and_return(
                double(exists?: true)
              )
              expect(subject.trade_policy_result).to eq(in_window_result)
            end

            it "returns #{out_of_window_result} when outside a trade window" do
              allow(subject.trade_windows).to receive(:current).and_return(
                double(exists?: false)
              )
              expect(subject.trade_policy_result).to eq(out_of_window_result)
            end
          end

          context "with no trade window" do
            it "returns #{out_of_window_result} when there is no trade window" do
              expect(subject.trade_policy_result).to eq(out_of_window_result)
            end
          end
        end
      end
    end

    it "returns :blocked for trade_policy_disabled regardless of games" do
      subject.trade_policy_disabled!
      allow(league).to receive(:games_started?).and_return(false)
      expect(subject.trade_policy_result).to be(:blocked)
    end
  end

  describe "#next_trade_window" do
    context "when the pool's trade policy is not windowed" do
      let!(:existing_window) { create(:trade_window, pool: subject) }

      [:disabled, :open, :approval_required].each do |policy|
        it "returns nil for #{policy}" do
          subject.update(trade_policy: policy)
          expect(subject.next_trade_window).to be_nil
        end
      end
    end

    [:windowed, :windowed_overflow].each do |policy|
      context "with #{policy}" do
        before(:each) { subject.update(trade_policy: policy) }

        it "returns nil when there are no trade windows" do
          expect(subject.next_trade_window).to be_nil
        end

        it "returns the upcoming window when none are current" do
          future_window = create(:trade_window, :future, pool: subject)
          expect(subject.next_trade_window).to eq(future_window)
        end

        it "returns the current window over a later upcoming one" do
          current_window = create(:trade_window, pool: subject)
          future_window = create(:trade_window, :future, pool: subject)
          expect(subject.next_trade_window).to eq(current_window)
        end
      end
    end
  end
end
