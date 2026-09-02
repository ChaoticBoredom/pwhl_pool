require "rails_helper"

RSpec.describe Trade::Window, type: :model do
  describe "validations" do
    it "is invalid without an open_window" do
      window = build(:trade_window, open_window: nil)
      expect(window).to_not be_valid
    end

    it "is invalid when the start is after the end" do
      window = build(:trade_window, open_window: 5.days.from_now..1.day.from_now)
      expect(window).to_not be_valid
    end

    it "is valid when the start is before the end" do
      window = build(:trade_window, open_window: 1.day.from_now..5.days.from_now)
      expect(window).to be_valid
    end

    it "is invalid when the start is the same as the end" do
      window_date = 4.days.from_now
      window = build(:trade_window, open_window: window_date..window_date)
      expect(window).to_not be_valid
    end
  end

  describe ".current" do
    let!(:current_window) { create(:trade_window) }
    let!(:future_window) { create(:trade_window, :future) }
    let!(:past_window) { create(:trade_window, :past) }

    it "returns only windows containing the current time" do
      expect(described_class.current).to match_array([current_window])
    end
  end
end
