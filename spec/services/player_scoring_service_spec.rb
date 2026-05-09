require "rails_helper"

RSpec.describe PlayerScoringService do
  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }
  let(:pool) { create(:pool, league: league, season_id: season_id) }
  let(:pool_team) { create(:pool_team, pool: pool) }

  let(:skater_scorings) do
    [
      create(:pool_scoring, :skater, :goals, pool: pool),
      create(:pool_scoring, :skater, :assists, pool: pool),
    ]
  end

  let(:goalie_scorings) do
    [
      create(:pool_scoring, :goalie, :saves, pool: pool),
      create(:pool_scoring, :goalie, :wins, pool: pool),
      create(:pool_scoring, :goalie, :shutouts, pool: pool),
    ]
  end

  def build_service(scorings)
    described_class.new(scorings)
  end

  def build_stat(start_time:, goals: 0, assists: 0)
    game = instance_double(League::Game, league: league, start_time: start_time)
    build(:pwhl_skater_stat, league: league, league_game: nil, goals: goals, assists: assists).tap do |stat|
      allow(stat).to receive(:league_game).and_return(game)
    end
  end

  def build_goalie_stat(start_time:, saves: 0, win: false, shutout: false)
    game = instance_double(League::Game, start_time: start_time)
    build(:pwhl_goalie_stat, league: league, league_game: nil, saves: saves, win: win, shutout: shutout).tap do |stat|
      allow(stat).to receive(:league_game).and_return(game)
    end
  end

  def create_team_player(league_player, pool_team, added_at:, dropped_at: nil)
    create(:pool_team_player,
      league_player: league_player,
      pool_team: pool_team,
      added_at: added_at,
      dropped_at: dropped_at
    )
  end

  let(:season_start) { Time.zone.parse("2025-11-21") }

  describe "#player_summaries" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    def summary_for(skater, records, added_at: season_start, dropped_at: nil)
      tp = create_team_player(skater, pool_team, added_at: added_at, dropped_at: dropped_at)
      service.player_summaries([tp], records)[tp.id]
    end

    context "with a game today" do
      let(:stat) { build_stat(start_time: 2.hours.ago, goals: 1, assists: 1) }
      let(:records) { { skater.id => [stat] } }

      [
        [:scores, :today, 5.0],
        [:scores, :yesterday, 0],
        [:scores, :week_to_date, 5.0],
        [:scores, :month_to_date, 5.0],
        [:scores, :season_to_date, 5.0],
      ].each do |summary_key, timeframe, expected|
        it "returns #{expected} for #{summary_key} #{timeframe}" do
          expect(summary_for(skater, records)[summary_key][timeframe]).to eq(expected)
        end
      end
    end

    context "with a game yesterday" do
      let(:stat) { build_stat(start_time: 1.day.ago, goals: 2) }
      let(:records) { { skater.id => [stat] } }

      [
        [:scores, :today, 0.0],
        [:scores, :yesterday, 6.0],
        [:scores, :week_to_date, 6.0],
        [:scores, :month_to_date, 6.0],
        [:scores, :season_to_date, 6.0],
      ].each do |summary_key, timeframe, expected|
        it "returns #{expected} for #{summary_key} #{timeframe}" do
          expect(summary_for(skater, records)[summary_key][timeframe]).to eq(expected)
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
        [:scores, :today, 3.0],
        [:scores, :yesterday, 0],
        [:scores, :week_to_date, 6.0],
        [:scores, :month_to_date, 10.0],
        [:scores, :season_to_date, 16.0],
      ].each do |summary_key, timeframe, expected|
        it "returns #{expected} for #{summary_key} #{timeframe}" do
          expect(summary_for(skater, records)[summary_key][timeframe]).to eq(expected)
        end
      end
    end

    describe "clipped_scores vs scores" do
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
          [:scores, :week_to_date, 6.0],
          [:scores, :today, 3.0],
          [:clipped_scores, :week_to_date, 3.0],
          [:clipped_scores, :today, 3.0],
        ].each do |summary_key, timeframe, expected|
          it "returns #{expected} for #{summary_key} #{timeframe}" do
            expect(summary_for(skater, records, added_at: added_at)[summary_key][timeframe]).to eq(expected)
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
          [:scores, :season_to_date, 9.0],
          [:clipped_scores, :season_to_date, 6.0],
        ].each do |summary_key, timeframe, expected|
          it "returns #{expected} for #{summary_key} #{timeframe}" do
            expect(summary_for(skater, records, added_at: season_start, dropped_at: dropped_at)[summary_key][timeframe]).to eq(expected)
          end
        end
      end

      context "backdated add" do
        let(:backdated_add) { Time.zone.parse("2026-01-01 00:00:00") }
        let(:records) do
          { skater.id => [build_stat(start_time: Time.zone.parse("2026-01-05 19:00:00"), goals: 1)] }
        end

        it "includes game when added_at is backdated" do
          expect(summary_for(skater, records, added_at: backdated_add)[:clipped_scores][:season_to_date]).to eq(3.0)
        end

        it "excludes game when added_at is today" do
          expect(summary_for(skater, records, added_at: Time.current)[:clipped_scores][:season_to_date]).to eq(0)
        end
      end

      context "backdated drop" do
        let(:backdated_drop) { Time.zone.parse("2026-01-09 23:59:59") }
        let(:records) do
          { skater.id => [build_stat(start_time: Time.zone.parse("2026-01-10 19:00:00"), goals: 1)] }
        end

        [
          [:clipped_scores, :season_to_date, 0],
          [:scores, :season_to_date, 3.0],
        ].each do |summary_key, timeframe, expected|
          it "returns #{expected} for #{summary_key} #{timeframe}" do
            expect(summary_for(skater, records, added_at: season_start, dropped_at: backdated_drop)[summary_key][timeframe]).to eq(expected)
          end
        end
      end

      context "same-day add and game" do
        let(:added_at) { Time.zone.parse("2026-01-13 10:00:00") }
        let(:records) do
          { skater.id => [build_stat(start_time: Time.zone.parse("2026-01-13 19:00:00"), goals: 1)] }
        end

        it "includes the game" do
          expect(summary_for(skater, records, added_at: added_at)[:clipped_scores][:season_to_date]).to eq(3.0)
        end
      end
    end

    describe "pool_score" do
      it "equals the clipped season total" do
        records = { skater.id => [build_stat(start_time: 3.days.ago, goals: 2)] }
        summary = summary_for(skater, records, added_at: 1.day.ago)
        expect(summary[:pool_score]).to eq(0)
      end
    end
  end

  describe "#player_summary" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    it "delegates to player_summaries" do
      stat = build_stat(start_time: 2.hours.ago, goals: 1)
      tp = create_team_player(skater, pool_team, added_at: season_start)
      records = { skater.id => [stat] }

      expect(service.player_summary(tp, records)).to eq(service.player_summaries([tp], records)[tp.id])
    end
  end

  describe "#team_scores" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:goalie) { create(:pwhl_goalie, league: league) }
    let(:service) { build_service(skater_scorings + goalie_scorings) }

    let(:pool_team_a) { create(:pool_team) }
    let(:pool_team_b) { create(:pool_team) }

    def setup_team_player(player, pool_team, added_at: season_start, dropped_at: nil)
      create(:pool_team_player,
        league_player: player,
        pool_team: pool_team,
        added_at: added_at,
        dropped_at: dropped_at
      )
    end

    it "returns a score for each team" do
      setup_team_player(skater, pool_team_a)
      setup_team_player(goalie, pool_team_b)

      records = {
        skater.id => [build_stat(start_time: 3.days.ago, goals: 2, assists: 1)],
        goalie.id => [build_goalie_stat(start_time: 2.days.ago, saves: 20, win: true, shutout: true)],
      }

      result = service.team_scores([pool_team_a, pool_team_b], records)
      expect(result.keys).to contain_exactly(pool_team_a.id, pool_team_b.id)
    end

    it "correctly scores a skater team" do
      setup_team_player(skater, pool_team_a)
      records = { skater.id => [build_stat(start_time: 3.days.ago, goals: 2, assists: 1)] }

      result = service.team_scores([pool_team_a], records)
      expect(result[pool_team_a.id]).to eq(8.0)
    end

    it "correctly scores a goalie team" do
      setup_team_player(goalie, pool_team_b)
      records = { goalie.id => [build_goalie_stat(start_time: 2.days.ago, saves: 20, win: true, shutout: true)] }

      result = service.team_scores([pool_team_b], records)
      expect(result[pool_team_b.id]).to eq(13.0)
    end

    it "returns an empty hash on empty input" do
      expect(service.team_scores([], {})).to eq({})
    end

    context "with a dropped player" do
      it "excludes stats outside the player's active window" do
        setup_team_player(skater, pool_team_a, added_at: season_start, dropped_at: 4.days.ago)
        records = { skater.id => [build_stat(start_time: 3.days.ago, goals: 2, assists: 1)] }

        result = service.team_scores([pool_team_a], records)
        expect(result[pool_team_a.id]).to eq(0)
      end
    end

    context "with multiple players on one team" do
      let(:skater2) { create(:pwhl_skater, league: league) }

      it "sums scores across all players" do
        setup_team_player(skater, pool_team_a)
        setup_team_player(skater2, pool_team_a)

        records = {
          skater.id => [build_stat(start_time: 3.days.ago, goals: 2, assists: 1)],
          skater2.id => [build_stat(start_time: 3.days.ago, goals: 1)],
        }

        result = service.team_scores([pool_team_a], records)
        expect(result[pool_team_a.id]).to eq(11.0)
      end
    end
  end

  describe "#raw_player_summaries" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    it "returns a summary hash for each player" do
      records = { skater.id => [build_stat(start_time: 1.day.ago)] }
      result = service.raw_player_summaries([skater], records)
      expect(result[skater.id]).to include(:today, :yesterday, :week_to_date, :month_to_date, :season_to_date)
    end

    it "returns full season stats without clipping" do
      records = { skater.id => [build_stat(start_time: Time.zone.parse("2025-11-22 19:00:00"), goals: 1)] }
      result = service.raw_player_summaries([skater], records)
      expect(result[skater.id][:season_to_date]).to eq(3.0)
    end

    it "returns an empty hash on empty input" do
      expect(service.raw_player_summaries([], {})).to eq({})
    end

    it "handles multiple players in one call" do
      skater2 = create(:pwhl_skater, league: league)
      records = {
        skater.id => [build_stat(start_time: 2.hours.ago, goals: 1)],
        skater2.id => [build_stat(start_time: 2.hours.ago, assists: 2)],
      }

      result = service.raw_player_summaries([skater, skater2], records)
      expect(result[skater.id][:today]).to eq(3.0)
      expect(result[skater2.id][:today]).to eq(4.0)
    end
  end

  describe "with no scoring rules for the player's position" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(goalie_scorings) }

    it "returns 0 for all windows" do
      tp = create_team_player(skater, pool_team, added_at: season_start)
      records = { skater.id => [build_stat(start_time: 2.hours.ago, goals: 5)] }
      result = service.player_summaries([tp], records)[tp.id]

      expect(result[:pool_score]).to eq(0)
      expect(result[:scores][:today]).to eq(0)
      expect(result[:clipped_scores][:today]).to eq(0)
    end
  end

  describe "with empty scorings" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service([]) }

    it "returns 0 for all windows" do
      tp = create_team_player(skater, pool_team, added_at: season_start)
      records = { skater.id => [build_stat(start_time: 2.hours.ago, goals: 5)] }
      result = service.player_summaries([tp], records)[tp.id]

      expect(result[:pool_score]).to eq(0)
      expect(result[:scores][:today]).to eq(0)
      expect(result[:clipped_scores][:today]).to eq(0)
    end
  end
end
