require "rails_helper"

RSpec.describe PlayerScoringService do
  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2024-2025" }
  let(:season_start) { Time.zone.parse("2024-10-01").beginning_of_day }
  let(:season_end)   { Time.zone.parse("2025-04-30").end_of_day }

  let(:pool) do
    create(:pool, league: league, season_id: season_id).tap do |p|
      allow(p).to receive(:start_end_range).and_return(season_start..season_end)
    end
  end

  let(:skater_scorings) do
    [
      create(:pool_scoring, :skater, :goals,   pool: pool),
      create(:pool_scoring, :skater, :assists, pool: pool),
    ]
  end

  let(:goalie_scorings) do
    [
      create(:pool_scoring, :goalie, :saves,    pool: pool),
      create(:pool_scoring, :goalie, :wins,     pool: pool),
      create(:pool_scoring, :goalie, :shutouts, pool: pool),
    ]
  end

  def build_service(scorings)
    described_class.new(scorings, pool)
  end

  def create_game(start_time: 4.hours.ago)
    create(:league_game, :final,
      league:     league,
      season_id:  season_id,
      start_time: start_time)
  end

  describe "skater scoring" do
    let(:skater) { create(:pwhl_skater, league: league) }
    let(:service) { build_service(skater_scorings) }

    describe "#score_for_date" do
      context "when the player has a stat record for the given date" do
        before do
          create(:pwhl_skater_stat, :scorer,
            league_player: skater,
            league_game:   create_game,
            goals:         2,
            assists:       1)
        end

        it "calculates score correctly: (2 goals * 3) + (1 assist * 2) = 8" do
          expect(service.score_for_date(Time.current, skater)).to eq(8.0)
        end
      end

      context "when the player has no stat record for the given date" do
        it "returns 0" do
          expect(service.score_for_date(Time.current, skater)).to eq(0)
        end
      end
    end

    describe "#score_for_today" do
      before do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game,
          goals:         1,
          assists:       0)
      end

      it "scores today's game: 1 goal * 3 = 3" do
        expect(service.score_for_today(skater)).to eq(3.0)
      end
    end

    describe "#score_for_yesterday" do
      context "when the player played yesterday" do
        before do
          create(:pwhl_skater_stat,
            league_player: skater,
            league_game:   create_game(start_time: 1.day.ago),
            goals:         1,
            assists:       2)
        end

        it "returns yesterday's score: (1 * 3) + (2 * 2) = 7" do
          expect(service.score_for_yesterday(skater)).to eq(7.0)
        end
      end

      context "when the player did not play yesterday" do
        it "returns 0" do
          expect(service.score_for_yesterday(skater)).to eq(0)
        end
      end
    end

    describe "#score_for_date_range" do
      before do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 3.days.ago),
          goals: 1, assists: 0)
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 5.days.ago),
          goals: 0, assists: 1)
      end

      it "sums scores across all records in the range" do
        range = 6.days.ago..1.day.ago.end_of_day
        expect(service.score_for_date_range(range, skater)).to eq(5.0)
      end

      it "excludes records outside the range" do
        range = 4.days.ago..1.day.ago.end_of_day
        expect(service.score_for_date_range(range, skater)).to eq(3.0)
      end
    end

    describe "#score_for_week_to_date" do
      around { |example| travel_to(Time.zone.parse("2025-01-08 12:00:00"), &example) }

      it "does not include today's game" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 2.hours.ago),
          goals: 1)

        expect(service.score_for_week_to_date(skater)).to eq(0)
      end

      it "includes games from earlier in the week" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 1.day.ago),
          goals: 1, assists: 1)

        expect(service.score_for_week_to_date(skater)).to eq(5.0)
      end

      it "excludes games from before the start of the week" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 3.days.ago),
          goals: 1)

        expect(service.score_for_week_to_date(skater)).to eq(0)
      end

      it "sums multiple games within the week" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 1.day.ago),
          goals: 1)
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 2.days.ago),
          goals: 0, assists: 2)

        expect(service.score_for_week_to_date(skater)).to eq(7.0)
      end
    end

    describe "#score_for_month_to_date" do
      around { |example| travel_to(Time.zone.parse("2025-01-15 12:00:00"), &example) }

      it "does not include today's game" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 2.hours.ago),
          goals: 1)

        expect(service.score_for_month_to_date(skater)).to eq(0)
      end

      it "includes games from earlier in the month" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 5.days.ago),
          goals: 2, assists: 1)

        expect(service.score_for_month_to_date(skater)).to eq(8.0)
      end

      it "excludes games from the previous month" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 20.days.ago),
          goals: 3)

        expect(service.score_for_month_to_date(skater)).to eq(0)
      end

      it "sums multiple games within the month" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 5.days.ago),
          goals: 1)
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 10.days.ago),
          goals: 0, assists: 1)

        expect(service.score_for_month_to_date(skater)).to eq(5.0)
      end
    end

    describe "#score_for_season" do
      before do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: season_start + 10.days),
          goals: 2, assists: 1)
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: season_end - 15.days),
          goals: 1, assists: 2)
      end

      it "sums all season records: (3 goals * 3) + (3 assists * 2) = 15" do
        expect(service.score_for_season(skater)).to eq(15.0)
      end

      it "excludes records from a different season" do
        other_game = create(:league_game, :final,
          league:     league,
          season_id:  "2023-2024",
          start_time: 10.days.ago)
        create(:pwhl_skater_stat, league_player: skater, league_game: other_game, goals: 5)

        expect(service.score_for_season(skater)).to eq(15.0)
      end
    end

    describe "#scores_summary" do
      it "returns a hash with the expected keys" do
        summary = service.scores_summary(skater)
        expect(summary.keys).to match_array(%i[season_to_date month_to_date week_to_date yesterday today])
      end

      it "folds today's score into all to_date values" do
        create(:pwhl_skater_stat,
          league_player: skater,
          league_game:   create_game(start_time: 1.hour.ago),
          goals: 1)

        summary = service.scores_summary(skater)
        today   = summary[:today]  # 1 goal * 3 = 3.0

        expect(summary[:week_to_date]).to   be >= today
        expect(summary[:month_to_date]).to  be >= today
        expect(summary[:season_to_date]).to be >= today
      end
    end
  end

  describe "goalie scoring" do
    let(:goalie) { create(:pwhl_goalie, league: league) }
    let(:service) { build_service(goalie_scorings) }

    describe "#score_for_date" do
      context "when the goalie records a shutout win" do
        before do
          create(:pwhl_goalie_stat, :shutout_win,
            league_player: goalie,
            league_game:   create_game,
            saves:         28)
        end

        it "scores saves + win + shutout: (28 * 0.25) + 5 + 3 = 15" do
          expect(service.score_for_date(Time.current, goalie)).to eq(15.0)
        end
      end

      context "when the goalie has no record" do
        it "returns 0" do
          expect(service.score_for_date(Time.current, goalie)).to eq(0)
        end
      end
    end

    describe "#score_for_date_range" do
      before do
        create(:pwhl_goalie_stat, :win,
          league_player: goalie,
          league_game:   create_game(start_time: 2.days.ago),
          saves: 25)
        create(:pwhl_goalie_stat, :loss,
          league_player: goalie,
          league_game:   create_game(start_time: 4.days.ago),
          saves: 20)
      end

      it "sums goalie stats across the range" do
        range = 5.days.ago..1.day.ago.end_of_day
        expect(service.score_for_date_range(range, goalie)).to eq(16.25)
      end
    end
  end

  describe "with no scoring rules for the player's position" do
    let(:skater)  { create(:pwhl_skater, league: league) }
    let(:service) { build_service(goalie_scorings) }

    it "returns 0" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game:   create_game,
        goals: 5)

      expect(service.score_for_today(skater)).to eq(0)
    end
  end

  describe "with empty scorings" do
    let(:skater)  { create(:pwhl_skater, league: league) }
    let(:service) { build_service([]) }

    it "returns 0 for any player" do
      create(:pwhl_skater_stat,
        league_player: skater,
        league_game:   create_game,
        goals: 3)

      expect(service.score_for_today(skater)).to eq(0)
    end
  end

  describe "#player_scorings_cache_key" do
    let(:service) { build_service(skater_scorings) }

    it "returns a 32-character MD5 hex string" do
      expect(service.player_scorings_cache_key).to match(/\A[0-9a-f]{32}\z/)
    end

    it "returns the same key for the same scorings" do
      service2 = build_service(skater_scorings)
      expect(service.player_scorings_cache_key).to eq(service2.player_scorings_cache_key)
    end

    it "returns a different key when scorings change" do
      different_scorings = [create(:pool_scoring, :skater, :shots, pool: pool)]
      service2 = build_service(different_scorings)
      expect(service.player_scorings_cache_key).not_to eq(service2.player_scorings_cache_key)
    end
  end
end
