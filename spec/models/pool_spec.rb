require "rails_helper"

RSpec.describe Pool, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:pool_type) }

  it { should allow_value(true).for(:trades_allowed) }
  it { should allow_value(false).for(:trades_allowed) }
  it { should_not allow_value(nil).for(:trades_allowed) }

  it { should allow_value(true).for(:trades_require_approval) }
  it { should allow_value(false).for(:trades_require_approval) }
  it { should_not allow_value(nil).for(:trades_require_approval) }

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

      it "calls the cache with a 3 day TTL" do
        expect(Rails.cache).to receive(:fetch).
          with(anything, hash_including(expires_in: 3.days)).
          and_call_original
        subject.start_end_range
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

      it "calls the cache with a 1 hour TTL" do
        expect(Rails.cache).to receive(:fetch).
          with(anything, hash_including(expires_in: 1.hour)).
          and_call_original
        subject.start_end_range
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

  describe "#trading_allowed_now?" do
    context "when trades_allowed is false" do
      before(:each) { subject.update(trades_allowed: false) }

      it "returns false" do
        expect(subject.trading_allowed_now?).to eq(false)
      end
    end

    context "when trades_allowed is true" do
      before(:each) { subject.update(trades_allowed: true) }

      context "when a game in the league has started" do
        before(:each) { allow(league).to receive(:games_started?).and_return(true) }

        it "should return false" do
          expect(subject.trading_allowed_now?).to eq(false)
        end
      end

      context "when no league games have started yet" do
        before(:each) { allow(league).to receive(:games_started?).and_return(false) }

        context "when pool has no trade windows" do
          it "returns true" do
            expect(subject.trading_allowed_now?).to eq(true)
          end
        end

        context "when pool has a trade window" do
          context "when trade window is in the future" do
            let!(:future_window) { create(:pool_trade_window, :future, pool: subject) }

            it "returns false" do
              expect(subject.trading_allowed_now?).to eq(false)
            end
          end

          context "when trade window is in the past" do
            let!(:past_window) { create(:pool_trade_window, :past, pool: subject) }

            it "returns false" do
              expect(subject.trading_allowed_now?).to eq(false)
            end
          end

          context "when trade window is current" do
            let!(:past_window) { create(:pool_trade_window, pool: subject, open_window: 2.hours.ago..2.hours.from_now) }

            it "returns true" do
              expect(subject.trading_allowed_now?).to eq(true)
            end
          end
        end
      end
    end
  end
end
