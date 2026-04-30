require "rails_helper"

RSpec.describe League, type: :model do
  it { should validate_presence_of(:name) }

  it { should have_many(:games) }

  let(:league) { create(:league) }

  describe "#first_game_today" do
    let!(:game_yesterday) { create(:league_game, league: league, start_time: 1.day.ago) }
    let!(:game_tomorrow) { create(:league_game, league: league, start_time: 1.day.from_now) }

    context "with no game today" do
      it "returns nil" do
        expect(league.first_game_today).to be_nil
      end
    end

    context "with one game today" do
      around { |ex| travel_to(Time.current.midday, &ex) }

      let!(:game_today) { create(:league_game, league: league, start_time: Time.current) }

      it "returns the start_time of today's game" do
        expect(league.first_game_today).to eq(Time.current)
      end
    end

    context "with multiple games today" do
      around { |ex| travel_to(Time.current.midday, &ex) }

      let!(:early_game) { create(:league_game, league: league, start_time: 3.hours.ago) }
      let!(:noon_game) { create(:league_game, league: league, start_time: Time.current) }
      let!(:evening_game) { create(:league_game, league: league, start_time: 6.hours.from_now) }

      it "returns the earliest start_time" do
        expect(league.first_game_today).to eq(early_game.start_time)
      end
    end
  end

  describe "#games_started?" do
    context "with no game today" do
      it "returns false" do
        expect(league.games_started?).to eq(false)
      end
    end

    context "with a game starting later today" do
      around { |ex| travel_to(Time.current.midday, &ex) }

      let!(:late_game) { create(:league_game, league: league, start_time: 5.minutes.from_now) }

      it "returns false" do
        expect(league.games_started?).to eq(false)
      end
    end

    context "with a game starting earlier today" do
      around { |ex| travel_to(Time.current.midday, &ex) }

      let!(:early_game) { create(:league_game, league: league, start_time: 5.minutes.ago) }

      it "returns true" do
        expect(league.games_started?).to eq(true)
      end
    end
  end
end
