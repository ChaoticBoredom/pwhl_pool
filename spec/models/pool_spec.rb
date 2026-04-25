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

      it "calls the cache with a 20 day TTL" do
        expect(Rails.cache).to receive(:fetch).
          with(anything, hash_including(expires_in: 20.days)).
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
end
