require "rails_helper"

RSpec.describe PlayerStatService do
  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }
  let(:pool) { create(:pool, league: league, season_id: season_id) }
  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:season_start) { Time.zone.parse("2025-11-21") }

  let(:service) { described_class.new }

  def build_stat(start_time:, goals: 0, assists: 0, shots: 0, penalty_minutes: 0.minutes, time_on_ice: 15.minutes)
    game = instance_double(League::Game, start_time: start_time)
    build(:pwhl_skater_stat,
      league: league,
      league_game: nil,
      goals: goals,
      assists: assists,
      shots: shots,
      penalty_minutes: penalty_minutes,
      time_on_ice: time_on_ice
    ).tap do |stat|
      allow(stat).to receive(:league_game).and_return(game)
    end
  end

  def create_team_player(league_player, added_at:, dropped_at: nil)
    create(:pool_team_player,
      league_player: league_player,
      pool_team: pool_team,
      added_at: added_at,
      dropped_at: dropped_at
    )
  end

  describe "#player_summaries" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }

    def summary_for(skater, records, added_at: season_start, dropped_at: nil)
      tp = create_team_player(skater, added_at: added_at, dropped_at: dropped_at)
      service.player_summaries([tp], records)[tp.id]
    end

    context "with a game today" do
      let(:records) { { skater.id => [build_stat(start_time: 2.hours.ago, goals: 1, assists: 1)] } }

      [
        [:goals, :today, 1],
        [:assists, :today, 1],
        [:goals, :yesterday, 0],
        [:assists, :yesterday, 0],
        [:goals, :week_to_date, 1],
        [:assists, :week_to_date, 1],
        [:goals, :month_to_date, 1],
        [:assists, :month_to_date, 1],
        [:goals, :season_to_date, 1],
        [:assists, :season_to_date, 1],
      ].each do |stat, timeframe, expected|
        it "returns #{expected} #{stat} in #{timeframe}" do
          expect(summary_for(skater, records)[:stats][timeframe][stat]).to eq(expected)
        end
      end
    end

    context "with a game yesterday" do
      let(:records) { { skater.id => [build_stat(start_time: 1.day.ago, goals: 2, assists: 1)] } }

      [
        [:goals, :today, 0],
        [:assists, :today, 0],
        [:goals, :yesterday, 2],
        [:assists, :yesterday, 1],
        [:goals, :week_to_date, 2],
        [:assists, :week_to_date, 1],
        [:goals, :month_to_date, 2],
        [:assists, :month_to_date, 1],
        [:goals, :season_to_date, 2],
        [:assists, :season_to_date, 1],
      ].each do |stat, timeframe, expected|
        it "returns #{expected} #{stat} in #{timeframe}" do
          expect(summary_for(skater, records)[:stats][timeframe][stat]).to eq(expected)
        end
      end
    end

    context "with games across multiple windows" do
      let(:records) do
        {
          skater.id => [
            build_stat(start_time: 2.hours.ago, goals: 1),
            build_stat(start_time: Time.zone.parse("2026-01-13 19:00:00"), goals: 1),
            build_stat(start_time: Time.zone.parse("2026-01-05 19:00:00"), assists: 2),
            build_stat(start_time: Time.zone.parse("2025-12-20 19:00:00"), goals: 2),
          ],
        }
      end

      [
        [:goals, :today, 1],
        [:goals, :yesterday, 0],
        [:goals, :week_to_date, 2],
        [:assists, :week_to_date, 0],
        [:goals, :month_to_date, 2],
        [:assists, :month_to_date, 2],
        [:goals, :season_to_date, 4],
        [:assists, :season_to_date, 2],
      ].each do |stat, timeframe, expected|
        it "returns #{expected} #{stat} in #{timeframe}" do
          expect(summary_for(skater, records)[:stats][timeframe][stat]).to eq(expected)
        end
      end
    end

    describe "clipped_stats vs stats" do
      context "when the player was added partway through the week" do
        let(:added_at) { Time.zone.parse("2026-01-14 10:00:00") }
        let(:records) do
          {
            skater.id => [
              build_stat(start_time: Time.zone.parse("2026-01-13 19:00:00"), goals: 1),
              build_stat(start_time: 2.hours.ago, goals: 1),
            ],
          }
        end

        [
          [:stats, :week_to_date, :goals, 2],
          [:clipped_stats, :week_to_date, :goals, 1],
          [:stats, :today, :goals, 1],
          [:clipped_stats, :today, :goals, 1],
        ].each do |summary_key, timeframe, stat, expected|
          it "returns #{expected} #{stat} in #{summary_key} #{timeframe}" do
            expect(summary_for(skater, records, added_at: added_at)[summary_key][timeframe][stat]).to eq(expected)
          end
        end
      end

      context "when the player was dropped" do
        let(:dropped_at) { Time.zone.parse("2026-01-09 18:00:00") }
        let(:records) do
          {
            skater.id => [
              build_stat(start_time: Time.zone.parse("2026-01-08 19:00:00"), goals: 2),
              build_stat(start_time: Time.zone.parse("2026-01-13 19:00:00"), goals: 1),
            ],
          }
        end

        [
          [:stats, :season_to_date, :goals, 3],
          [:clipped_stats, :season_to_date, :goals, 2],
        ].each do |summary_key, timeframe, stat, expected|
          it "returns #{expected} #{stat} in #{summary_key} #{timeframe}" do
            expect(summary_for(skater, records, added_at: season_start, dropped_at: dropped_at)[summary_key][timeframe][stat]).to eq(expected)
          end
        end
      end
    end

    it "returns zeroed stat hash for a player with no records" do
      tp = create_team_player(skater, added_at: season_start)
      result = service.player_summaries([tp], {})[tp.id]
      expect(result[:stats][:today][:goals]).to eq(0)
    end
  end

  describe "#player_summary" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }

    it "delegates to player_summaries" do
      tp = create_team_player(skater, added_at: season_start)
      stat = build_stat(start_time: 2.hours.ago, goals: 1)
      records = { skater.id => [stat] }

      expect(service.player_summary(tp, records)).to eq(service.player_summaries([tp], records)[tp.id])
    end
  end
end
