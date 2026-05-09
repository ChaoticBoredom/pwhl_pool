require "rails_helper"

RSpec.describe DateFiltering do
  let(:test_class) do
    Class.new do
      include DateFiltering

      def calculate_aggregate(records, position)
        # Sum goals, and that's it
        records.sum(&:goals)
      end

      def default_return
        0
      end
    end
  end

  let(:service) { test_class.new }

  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }

  let(:skater) { create(:pwhl_skater, league: league) }

  def create_game(start_time: 4.hours.ago)
    create(:league_game,
      :final,
      league: league,
      season_id: season_id,
      start_time: start_time
    )
  end

  def create_stat(start_time:, goals: 1)
    create(:pwhl_skater_stat,
      goals: goals,
      league: league,
      league_game: create_game(start_time: start_time)
    )
  end

  describe "#initialize" do
    let(:incomplete_class) { Class.new { include DateFiltering } }
    let(:incomplete_service) { incomplete_class.new }

    it "raises an error if extending class does not define a calculate_aggregate method" do
      incomplete_service = Class.new { include DateFiltering }

      expect { incomplete_service.new.send(:calculate_aggregate, [], :skater) }.
        to raise_error(NotImplementedError, /calculate_aggregate/)
    end

    it "raises an error if extending class does not define a default_return method" do
      incomplete_service = Class.new { include DateFiltering }

      expect { incomplete_service.new.send(:default_return) }.
        to raise_error(NotImplementedError, /default_return/)
    end
  end

  describe "#records_in_range" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    it "includes a record whose game falls within the range" do
      stat = create_stat(start_time: 1.day.ago)
      result = service.send(:records_in_range, [stat], 2.days.ago..Time.current)
      expect(result).to include(stat)
    end

    it "excludes a record whose game falls outside the range" do
      stat = create_stat(start_time: 3.days.ago)
      result = service.send(:records_in_range, [stat], 2.days.ago..Time.current)
      expect(result).to_not include(stat)
    end

    it "includes a record at exactly the range boundary" do
      stat = create_stat(start_time: 2.days.ago)
      result = service.send(:records_in_range, [stat], 2.days.ago..Time.current)
      expect(result).to include(stat)
    end

    it "returns an empty array when no records fall in range" do
      stat = create_stat(start_time: 5.days.ago)
      result = service.send(:records_in_range, [stat], 2.days.ago..Time.current)
      expect(result).to be_empty
    end
  end

  describe "#intersect_ranges" do
    let(:base) { Time.zone.parse("2026-01-10")..Time.zone.parse("2026-01-20") }

    it "returns the overlapping portion of two ranges" do
      other = Time.zone.parse("2026-01-15")..Time.zone.parse("2026-01-25")
      result = service.send(:intersect_ranges, base, other)
      expect(result).to eq(Time.zone.parse("2026-01-15")..Time.zone.parse("2026-01-20"))
    end

    it "returns nil when ranges do not overlap" do
      other = Time.zone.parse("2026-01-21")..Time.zone.parse("2026-01-25")
      result = service.send(:intersect_ranges, base, other)
      expect(result).to be_nil
    end

    it "returns a single point range when ranges share only one boundary" do
      other = Time.zone.parse("2026-01-20")..Time.zone.parse("2026-01-25")
      result = service.send(:intersect_ranges, base, other)
      expect(result).to eq(Time.zone.parse("2026-01-20")..Time.zone.parse("2026-01-20"))
    end

    it "returns the full range when one contains the other" do
      inner = Time.zone.parse("2026-01-12")..Time.zone.parse("2026-01-18")
      result = service.send(:intersect_ranges, base, inner)
      expect(result).to eq(inner)
    end
  end

  describe "#score_window" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:window) { Time.current.beginning_of_day..Time.current.end_of_day }
    let!(:noise) { create_stat(start_time: 10.days.ago, goals: 99) }

    it "returns the aggregate for records within the window" do
      stat = create_stat(start_time: 2.hours.ago, goals: 2)
      result = service.send(:score_window, [stat, noise], :skater, window)
      expect(result).to eq(2)
    end

    it "excludes records outside the window" do
      stat = create_stat(start_time: 1.day.ago, goals: 2)
      result = service.send(:score_window, [stat, noise], :skater, window)
      expect(result).to eq(0)
    end

    it "returns default_return when clip_range does not intersect the window" do
      stat = create_stat(start_time: 2.hours.ago, goals: 2)
      clip_range = 5.days.ago..3.days.ago
      result = service.send(:score_window, [stat, noise], :skater, window, clip_range: clip_range)
      expect(result).to eq(0)
    end

    it "restricts records to the intersection of window and clip_range" do
      stat_inside = create_stat(start_time: 30.minutes.ago, goals: 2)
      clip_range = 1.hour.ago..Time.current.end_of_day
      result = service.send(:score_window, [stat_inside, noise], :skater, window, clip_range: clip_range)
      expect(result).to eq(2)
    end

    it "excludes a record outside the clip_range even if inside the window" do
      stat = create_stat(start_time: Time.current.beginning_of_day, goals: 2)
      clip_range = 1.hour.ago..Time.current.end_of_day
      result = service.send(:score_window, [stat, noise], :skater, window, clip_range: clip_range)
      expect(result).to eq(0)
    end
  end

  describe "#build_windowed_summary" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    it "raises LocalJumpError without a block" do
      expect { service.send(:build_windowed_summary, [], :skater) }.
        to raise_error(LocalJumpError)
    end

    it "returns today correctly" do
      stat = create_stat(start_time: 1.hour.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat], :skater) { |td, today| td + today }
      expect(result[:today]).to eq(1)
    end

    it "returns yesterday correctly" do
      stat = create_stat(start_time: 1.day.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat], :skater) { |td, today| td + today }
      expect(result[:yesterday]).to eq(1)
    end

    it "excludes today from yesterday" do
      stat = create_stat(start_time: 1.hour.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat], :skater) { |td, today| td + today }
      expect(result[:yesterday]).to eq(0)
    end

    it "yields week_to_date and today to combine" do
      stat_wtd = create_stat(start_time: 2.days.ago, goals: 1)
      stat_today = create_stat(start_time: 1.hour.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat_wtd, stat_today], :skater) { |td, today| td + today }
      expect(result[:week_to_date]).to eq(2)
    end

    it "yields month_to_date and today to combine" do
      stat_mtd = create_stat(start_time: 5.days.ago, goals: 1)
      stat_today = create_stat(start_time: 1.hour.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat_mtd, stat_today], :skater) { |td, today| td + today }
      expect(result[:month_to_date]).to eq(2)
    end

    it "yields season_to_date and today to combine" do
      stat_std = create_stat(start_time: 30.days.ago, goals: 1)
      stat_today = create_stat(start_time: 1.hour.ago, goals: 1)
      result = service.send(:build_windowed_summary, [stat_std, stat_today], :skater) { |td, today| td + today }
      expect(result[:season_to_date]).to eq(2)
    end
  end

  describe "#week_to_date_range" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    it "starts at the beginning of the current week" do
      expect(service.send(:week_to_date_range).begin).
        to eq(Time.current.beginning_of_week)
    end

    it "ends at the end of yesterday" do
      expect(service.send(:week_to_date_range).end).
        to eq(1.day.ago.end_of_day)
    end

    it "excludes today" do
      expect(service.send(:week_to_date_range)).
        to_not cover(Time.current)
    end
  end

  describe "#month_to_date_range" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    it "starts at the beginning of the current month" do
      expect(service.send(:month_to_date_range).begin).
        to eq(Time.current.beginning_of_month)
    end

    it "ends at the end of yesterday" do
      expect(service.send(:month_to_date_range).end).
        to eq(1.day.ago.end_of_day)
    end

    it "excludes today" do
      expect(service.send(:month_to_date_range)).
        to_not cover(Time.current)
    end
  end

  describe "#season_to_date_range" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    it "ends at the end of yesterday" do
      expect(service.send(:season_to_date_range).end).
        to eq(1.day.ago.end_of_day)
    end

    it "excludes today" do
      expect(service.send(:season_to_date_range)).
        to_not cover(Time.current)
    end

    it "covers any date before today" do
      expect(service.send(:season_to_date_range)).
        to cover(Time.zone.parse("2020-01-01"))
    end
  end
end
