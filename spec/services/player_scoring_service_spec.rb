require "rails_helper"

RSpec.describe PlayerScoringService do
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
    described_class.new(scorings, pool)
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

  describe "#scores_summary via player_summaries" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    def summary_for(skater, added_at: season_start, dropped_at: nil)
      tp = create_team_player(skater,
        pool_team,
        added_at: added_at,
        dropped_at: dropped_at
      )
      service.player_summaries([tp])[tp.id]
    end

    context "with a game today" do
      before(:each) do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: 2.hours.ago),
          goals: 1, assists: 1
        )
      end

      it "scores today correctly" do
        expect(summary_for(skater)[:scores][:today]).to eq(5.0)
      end

      it "scores yesterday correctly" do
        expect(summary_for(skater)[:scores][:yesterday]).to eq(0)
      end

      it "scores week_to_date correctly" do
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(5.0)
      end

      it "scores month_to_date correctly" do
        expect(summary_for(skater)[:scores][:month_to_date]).to eq(5.0)
      end

      it "scores season_to_date  correctly" do
        expect(summary_for(skater)[:scores][:season_to_date]).to eq(5.0)
      end
    end

    context "with a game yesterday" do
      before(:each) do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago),
          goals: 2, assists: 0
        )
      end

      it "scores today correctly" do
        expect(summary_for(skater)[:scores][:today]).to eq(0.0)
      end

      it "scores yesterday correctly" do
        expect(summary_for(skater)[:scores][:yesterday]).to eq(6.0)
      end

      it "scores week_to_date correctly" do
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(6.0)
      end

      it "scores month_to_date correctly" do
        expect(summary_for(skater)[:scores][:month_to_date]).to eq(6.0)
      end

      it "scores season_to_date  correctly" do
        expect(summary_for(skater)[:scores][:season_to_date]).to eq(6.0)
      end
    end

    context "with games across multiple windows" do
      before(:each) do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 2.hours.ago),
          goals: 1)

        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: Time.zone.parse("2026-01-13 19:00:00")),
          goals: 1)

        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: Time.zone.parse("2026-01-05 19:00:00")),
          assists: 2)

        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: Time.zone.parse("2025-12-20 19:00:00")),
          goals: 2)
      end

      it "scores today correctly" do
        expect(summary_for(skater)[:scores][:today]).to eq(3.0)
      end

      it "scores yesterday correctly" do
        expect(summary_for(skater)[:scores][:yesterday]).to eq(0)
      end

      it "scores week_to_date correctly" do
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(6.0)
      end

      it "scores month_to_date correctly" do
        expect(summary_for(skater)[:scores][:month_to_date]).to eq(10.0)
      end

      it "scores season_to_date  correctly" do
        expect(summary_for(skater)[:scores][:season_to_date]).to eq(16.0)
      end
    end

    describe "window boundary precision" do
      it "includes a game at exactly beginning_of_day today" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: Time.current.beginning_of_day),
          goals: 1)
        expect(summary_for(skater)[:scores][:today]).to eq(3.0)
      end

      it "includes a game at exactly end_of_day yesterday in week_to_date" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago.end_of_day),
          goals: 1)
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(3.0)
      end

      it "includes a game at exactly beginning_of_week in week_to_date" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: Time.current.beginning_of_week),
          goals: 1)
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(3.0)
      end

      it "excludes a game one second before beginning_of_week" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: Time.current.beginning_of_week - 1.second),
          goals: 1)
        expect(summary_for(skater)[:scores][:week_to_date]).to eq(0)
      end

      it "includes a game at exactly beginning_of_month in month_to_date" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: Time.current.beginning_of_month),
          goals: 1)
        expect(summary_for(skater)[:scores][:month_to_date]).to eq(3.0)
      end

      it "excludes a game one second before beginning_of_month" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: Time.current.beginning_of_month - 1.second),
          goals: 1)
        expect(summary_for(skater)[:scores][:month_to_date]).to eq(0)
      end
    end

    describe "clipped_scores vs scores" do
      context "when the player was added partway through the week" do
        let(:added_at) { Time.zone.parse("2026-01-14 10:00:00") }

        before(:each) do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: Time.zone.parse("2026-01-13 19:00:00")),
            goals: 1)

          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: 2.hours.ago),
            goals: 1)
        end

        it "includes the 13th in unclipped week_to_date" do
          scores = summary_for(skater, added_at: added_at)[:scores]
          expect(scores[:week_to_date]).to eq(6.0)
        end

        it "includes today in unclipped data" do
          scores = summary_for(skater, added_at: added_at)[:scores]
          expect(scores[:today]).to eq(3.0)
        end

        it "excludes the 13th in clipped week_to_date" do
          scores = summary_for(skater, added_at: added_at)[:clipped_scores]
          expect(scores[:week_to_date]).to eq(3.0)
        end

        it "includes today in clipped data" do
          scores = summary_for(skater, added_at: added_at)[:clipped_scores]
          expect(scores[:today]).to eq(3.0)
        end
      end

      context "when the player was dropped" do
        let(:dropped_at) { Time.zone.parse("2026-01-09 18:00:00") }

        before(:each) do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: Time.zone.parse("2026-01-8 19:00:00")),
            goals: 2)

          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: Time.zone.parse("2026-01-13 19:00:00")),
            goals: 1)
        end

        it "includes post-drop game in unclipped season_to_date" do
          scores = summary_for(skater, added_at: season_start, dropped_at: dropped_at)[:scores]
          expect(scores[:season_to_date]).to eq(9.0)
        end

        it "excludes post-drop game from clipped season_to_date" do
          clipped = summary_for(skater, added_at: season_start, dropped_at: dropped_at)[:clipped_scores]
          expect(clipped[:season_to_date]).to eq(6.0)
        end
      end

      context "backdated add (admin approved trade with backdated added_at)" do
        let(:backdated_add) { Time.zone.parse("2026-01-01 00:00:00") }

        before(:each) do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: Time.zone.parse("2026-01-05 19:00:00")),
            goals: 1)
        end

        it "includes game when added_at is backdated" do
          clipped = summary_for(skater, added_at: backdated_add)[:clipped_scores]
          expect(clipped[:season_to_date]).to eq(3.0)
        end

        it "excludes game when added_at is today" do
          clipped = summary_for(skater, added_at: Time.current)[:clipped_scores]
          expect(clipped[:season_to_date]).to eq(0)
        end
      end

      context "backdated drop (admin corrects a drop date)" do
        let(:backdated_drop) { Time.zone.parse("2026-01-09 23:59:59") }

        before(:each) do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: Time.zone.parse("2026-01-10 19:00:00")),
            goals: 1)
        end

        it "excludes a game played after the backdated drop time" do
          clipped = summary_for(skater, added_at: season_start, dropped_at: backdated_drop)[:clipped_scores]
          expect(clipped[:season_to_date]).to eq(0)
        end

        it "includes a game played after the backdated drop in unclipped" do
          scores = summary_for(skater, added_at: season_start, dropped_at: backdated_drop)[:scores]
          expect(scores[:season_to_date]).to eq(3.0)
        end
      end

      context "same-day add and game" do
        let(:added_at) { Time.zone.parse("2026-01-13 10:00:00") }
        let(:game_time) { Time.zone.parse("2026-01-13 19:00:00") }

        before(:each) do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game: create_game(start_time: game_time),
            goals: 1)
        end

        it "includes the game" do
          clipped = summary_for(skater, added_at: added_at)[:clipped_scores]
          expect(clipped[:season_to_date]).to eq(3.0)
        end
      end
    end

    describe "pool_score" do
      it "equals the clipped season total" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game: create_game(start_time: 3.days.ago),
          goals: 2)

        added_at = 1.day.ago
        summary = summary_for(skater, added_at: added_at)

        expect(summary[:pool_score]).to eq(0)
        expect(summary[:clipped_scores][:season_to_date]).to eq(0)
      end
    end
  end

  describe "#bulk_team_scores" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:goalie) { create(:pwhl_goalie, league: league) }
    let(:service) { build_service(skater_scorings + goalie_scorings) }

    let(:pool_team_a) { create(:pool_team) }
    let(:pool_team_b) { create(:pool_team) }

    before(:each) do
      create_team_player(skater, pool_team_a, added_at: season_start)
      create_team_player(goalie, pool_team_b, added_at: season_start)

      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game(start_time: 3.days.ago),
        goals: 2, assists: 1)

      create(:pwhl_goalie_stat, :shutout_win,
        league_player: goalie,
        league_game: create_game(start_time: 2.days.ago),
        saves: 20)
    end

    it "returns a score for each team" do
      result = service.bulk_team_scores([pool_team_a, pool_team_b])
      expect(result.keys).to contain_exactly(pool_team_a.id, pool_team_b.id)
    end

    it "correctly scores a skater team" do
      result = service.bulk_team_scores([pool_team_a, pool_team_b])
      expect(result[pool_team_a.id]).to eq(8.0)
    end

    it "correctly scores a goalie team" do
      result = service.bulk_team_scores([pool_team_a, pool_team_b])
      expect(result[pool_team_b.id]).to eq(13.0)
    end

    it "returns an empty hash on empty input" do
      expect(service.bulk_team_scores([])).to eq({})
    end

    it "excludes stats from a different season" do
      old_game = create(:league_game, :final, league: league, season_id: "2024-2025", start_time: 3.days.ago)
      create(:pwhl_skater_stat, league_player: skater, league_game: old_game, goals: 5)

      result = service.bulk_team_scores([pool_team_a])
      expect(result[pool_team_a.id]).to eq(8.0)
    end

    context "with a dropped player" do
      let(:dropped_team) { create(:pool_team) }

      it "excludes stats outside the player's active window" do
        create_team_player(skater,
          dropped_team,
          added_at: season_start,
          dropped_at: 4.days.ago)
        result = service.bulk_team_scores([dropped_team])
        expect(result[dropped_team.id]).to eq(0)
      end
    end

    context "with multiple players on one team" do
      let(:skater2) { create(:pwhl_skater, league: league) }

      before(:each) do
        create(:pwhl_skater_stat,
          league_player: skater2,
          league_game: create_game(start_time: 3.days.ago),
          goals: 1)
      end

      it "sums scores across all players on the team" do
        create_team_player(skater2, pool_team_a, added_at: season_start)
        result = service.bulk_team_scores([pool_team_a])
        expect(result[pool_team_a.id]).to eq(11.0)
      end
    end
  end

  describe "#raw_player_summaries" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    it "returns a summary hash for each player" do
      result = service.raw_player_summaries([skater])
      expect(result[skater.id]).to include(
        :today, :yesterday, :week_to_date, :month_to_date, :season_to_date
      )
    end

    it "does not clip scores - returns full season stats" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game(start_time: Time.zone.parse("2025-11-22 19:00:00")),
        goals: 1)

      result = service.raw_player_summaries([skater])
      expect(result[skater.id][:season_to_date]).to eq(3.0)
    end

    it "returns an empty hash when input is empty" do
      expect(service.raw_player_summaries([])).to eq({})
    end

    it "handles multiple players in one call" do
      skater2 = create(:pwhl_skater, league: league)
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game,
        goals: 1)
      create(:pwhl_skater_stat,
        league_player: skater2,
        league_game: create_game,
        assists: 2)

      result = service.raw_player_summaries([skater, skater2])
      expect(result[skater.id][:today]).to eq(3.0)
      expect(result[skater2.id][:today]).to eq(4.0)
    end
  end

  describe "#raw_player_season_totals" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    it "returns a flat Float total per player" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game(start_time: 3.days.ago),
        goals: 2, assists: 1)

      result = service.raw_player_season_totals([skater])
      expect(result[skater.id]).to eq(8.0)
    end

    it "returns an empty hash when input is empty" do
      expect(service.raw_player_season_totals([])).to eq({})
    end

    it "returns 0.0 for a a player with no stats in the season" do
      expect(service.raw_player_season_totals([skater])[skater.id]).to eq(0)
    end

    it "handles multiple players in one call" do
      skater2 = create(:pwhl_skater, league: league)
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game(start_time: 3.days.ago),
        goals: 1)
      create(:pwhl_skater_stat,
        league_player: skater2,
        league_game: create_game(start_time: 3.days.ago),
        assists: 2)

      result = service.raw_player_season_totals([skater, skater2])
      expect(result[skater.id]).to eq(3.0)
      expect(result[skater2.id]).to eq(4.0)
    end

    context "with an explicit season_id override" do
      let(:reference_season_id) { "2023" }
      let!(:non_included_game) { create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game(start_time: 3.days.ago),
        goals: 5) }

      it "loads stats from the specified season" do
        ref_game = create(:league_game,
          :final,
          league: league,
          season_id: reference_season_id,
          start_time: Time.zone.parse("2023-01-01 12:00:00"))
        create(:pwhl_skater_stat, league_player: skater,
          league_game: ref_game, goals: 1)

        result = service.raw_player_season_totals([skater], season_id: reference_season_id)
        expect(result[skater.id]).to eq(3.0)
      end

      it "returns 0 for a player with no stats in the reference_season" do
        result = service.raw_player_season_totals([skater], season_id: reference_season_id)
        expect(result[skater.id]).to eq(0)
      end
    end

    context "uses pool.display_season_id" do
      let(:reference_season_id) { "2023" }
      let(:pool_with_reference) do
        create(:pool, league: league, season_id: "2025-2026", reference_season_id: "2023").tap do |p|
          allow(p).to receive(:start_end_range).and_return(season_start..season_end)
        end
      end

      let(:reference_service) { described_class.new(skater_scorings, pool_with_reference) }

      it "uses the reference season when no explicit season_id is passed" do
        ref_game = create(:league_game,
          :final,
          league: league,
          season_id: reference_season_id,
          start_time: Time.zone.parse("2026-01-01 12:00:00"))
        create(:pwhl_skater_stat, league_player: skater,
          league_game: ref_game, goals: 2)

        result = reference_service.raw_player_season_totals([skater])
        expect(result[skater.id]).to eq(6.0)
      end
    end
  end

  describe "with no scoring rules for the player's position" do
    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(goalie_scorings) }

    it "returns 0 for all windows" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game,
        goals: 5)

      tp = create_team_player(skater, pool_team, added_at: season_start)
      result = service.player_summaries([tp])[tp.id]

      expect(result[:pool_score]).to eq(0)
      expect(result[:scores][:today]).to eq(0)
      expect(result[:clipped_scores][:today]).to eq(0)
    end
  end

  describe "with empty scorings" do
    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service([]) }

    it "returns 0 for all windows" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game: create_game,
        goals: 5)

      tp = create_team_player(skater, pool_team, added_at: season_start)
      result = service.player_summaries([tp])[tp.id]

      expect(result[:pool_score]).to eq(0)
      expect(result[:scores][:today]).to eq(0)
      expect(result[:clipped_scores][:today]).to eq(0)
    end
  end

  describe "season boundary" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    it "excludes a game from outside the season entirely" do
      out_of_season_game = create(:league_game, :final,
        league: league,
        season_id: "2024-2025",
        start_time: 1.day.ago)
      create(:pwhl_skater_stat, league_player: skater, league_game: out_of_season_game, goals: 5)

      tp = create_team_player(skater, pool_team, added_at: season_start)
      result = service.player_summaries([tp])[tp.id]

      expect(result[:scores][:season_to_date]).to eq(0)
    end
  end
end
