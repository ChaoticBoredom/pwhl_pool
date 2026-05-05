require "rails_helper"

RSpec.describe RecordCollector do
  let(:test_service) do
    Class.new do
      include RecordCollector

      def initialize(pool)
        @pool = pool
      end

      def stat_classes
        [Pwhl::SkaterStat]
      end

      def calculate_aggregate(records, position)
        # Sum goals, and that's it
        records.sum(&:goals)
      end

      # Expose the private method so we can test things!
      def test_load(*args, **kwargs)
        load_season_records_for(*args, **kwargs)
      end
    end
  end

  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }

  let(:season_start) { Time.zone.parse("2025-11-21") }
  let(:season_end) { Time.zone.parse("2026-04-30") }

  let(:pool) do
    create(:pool, league: league, season_id: season_id).tap do |p|
      allow(p).to receive(:start_end_range).and_return(season_start..season_end)
    end
  end

  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:skater) { create(:pwhl_skater, league: league) }
  let(:skater_scorings) do
    [
      create(:pool_scoring, :skater, :goals, pool: pool),
      create(:pool_scoring, :skater, :assists, pool: pool),
    ]
  end

  def create_game(start_time: 4.hours.ago)
    create(:league_game,
      :final,
      league: league,
      season_id: season_id,
      start_time: start_time
    )
  end

  def create_team_player(league_player, pool_team, added_at:, dropped_at: nil)
    create(:pool_team_player,
      league_player: league_player,
      pool_team: pool_team,
      added_at: added_at,
      dropped_at: dropped_at
    )
  end

  describe "#initialize" do
    it "raises an error if extending class does not init @pool" do
      incomplete_service = Class.new { include RecordCollector }.new
      expect { incomplete_service.send(:load_season_records_for, []) }.to raise_error(ArgumentError)
    end

    it "raises an error if extending class does not define a stat_classes method" do
      incomplete_service = Class.new do
        include RecordCollector

        def initialize(pool)
          @pool = pool
        end
      end

      expect { incomplete_service.new(pool).send(:load_season_records_for, [skater.id]) }.to raise_error(NotImplementedError, /stat_classes/)
    end

    it "raises an error if extending class does not define a calculate_aggregate method" do
      incomplete_service = Class.new do
        include RecordCollector

        def initialize(pool)
          @pool = pool
        end
      end

      expect { incomplete_service.new(pool).send(:load_season_records_for, [skater.id]) }.to raise_error(NotImplementedError, /stat_classes/)
    end
  end

  context "with a game today" do
    around { |ex| travel_to(Time.current.mid_day, &ex) }

    before(:each) do
      create(:pwhl_skater_stat,
        league_player: :skater,
        league_game: create_game(start_time: 2.hours.ago),
        goals: 2
      )
    end
  end
end
