require "rails_helper"

RSpec.describe PlayerRecordQuery do
  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }

  def create_game(start_time:, season_id: self.season_id)
    create(:league_game, :final,
      league: league,
      season_id: season_id,
      start_time: start_time
    )
  end

  def build_query(players, season_id: self.season_id)
    described_class.new(players, season_id: season_id)
  end

  describe "#records" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    context "with League::Player input" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "returns records keyed by league_player_id" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater]).records
        expect(result).to have_key(skater.id)
      end

      it "uses the player id directly" do
        skater_stat = create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater]).records
        expect(result[skater.id]).to include(skater_stat)
      end
    end

    context "with Pool::TeamPlayer input" do
      let(:skater) { create(:pwhl_skater, league: league) }
      let(:pool) { create(:pool, league: league, season_id: season_id) }
      let(:pool_team) { create(:pool_team, pool: pool) }
      let(:team_player) do
        create(:pool_team_player,
          league_player: skater,
          pool_team: pool_team,
          added_at: 2.weeks.ago,
          dropped_at: 1.week.ago)
      end

      it "returns records keyed by league_player_id" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([team_player]).records
        expect(result).to have_key(skater.id)
      end

      it "deduplicates when multiple team_players share a league_player_id" do
        team_player_2 = create(:pool_team_player,
          league_player: skater,
          pool_team: pool_team,
          added_at: 1.day.ago)

        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([team_player, team_player_2]).records
        expect(result[skater.id].length).to eq(1)
      end
    end

    context "with an unsupported player type" do
      it "raises ArgumentError" do
        expect { build_query(["not_a_player"]).records }.
          to raise_error(ArgumentError, /Unsupported player type/)
      end
    end

    context "with empty input" do
      it "returns an empty hash" do
        expect(build_query([]).records).to eq({})
      end
    end

    context "season scoping" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "includes records from the given season" do
        stat = create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater]).records
        expect(result[skater.id]).to include(stat)
      end

      it "excludes records from a different season" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago, season_id: "2024-2025"))

        result = build_query([skater]).records
        expect(result).to_not have_key(skater.id)
      end

      it "respects an explicit season_id override" do
        ref_game = create(:league_game, :final,
          league: league,
          season_id: "2023-2024",
          start_time: Time.zone.parse("2024-01-01 12:00:00"))
        stat = create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: ref_game)

        result = build_query([skater], season_id: "2023-2024").records
        expect(result[skater.id]).to include(stat)
      end
    end

    context "with mixed stat types" do
      let(:skater) { create(:pwhl_skater, league: league) }
      let(:goalie) { create(:pwhl_goalie, league: league) }

      it "returns skater stats under the skater's league_player_id" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater, goalie]).records
        expect(result[skater.id].first).to be_a(Pwhl::SkaterStat)
      end

      it "returns goalie stats under the goalie's league_player_id" do
        create(:pwhl_goalie_stat,
          league: league,
          league_player: goalie,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater, goalie]).records
        expect(result[goalie.id].first).to be_a(Pwhl::GoalieStat)
      end

      it "returns both stat types in the same call" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))
        create(:pwhl_goalie_stat,
          league: league,
          league_player: goalie,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater, goalie]).records
        expect(result.keys).to contain_exactly(skater.id, goalie.id)
      end
    end

    context "eager loading" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "eager loads league_game on returned records" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        records = build_query([skater]).records
        expect(records[skater.id].first.association(:league_game)).to be_loaded
      end
    end

    context "historical vs today split" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "includes a game from yesterday" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query([skater]).records
        expect(result[skater.id].length).to eq(1)
      end

      it "includes a game from today" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.hour.ago))

        result = build_query([skater]).records
        expect(result[skater.id].length).to eq(1)
      end

      it "includes games from both today and yesterday" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.hour.ago))

        result = build_query([skater]).records
        expect(result[skater.id].length).to eq(2)
      end
    end

    context "caching" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "passes historical record ids through Rails.cache.fetch" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        expect(Rails.cache).to receive(:fetch).and_call_original

        build_query([skater]).records
      end
    end
  end

  describe "#cache_key" do
    let(:skater) { create(:pwhl_skater, league: league) }

    it "produces different cache keys across days" do
      key_today = build_query([skater]).send(:cache_key)
      key_tomorrow = travel_to(1.day.from_now) { build_query([skater]).send(:cache_key) }

      expect(key_today).to_not eq(key_tomorrow)
    end

    it "produces different cache keys for different player id sets" do
      skater_2 = create(:pwhl_skater, league: league)

      key_one = build_query([skater]).send(:cache_key)
      key_two = build_query([skater_2]).send(:cache_key)

      expect(key_one).to_not eq(key_two)
    end

    it "produces the same cache key regardless of player input order" do
      skater_2 = create(:pwhl_skater, league: league)

      key_a = build_query([skater, skater_2]).send(:cache_key)
      key_b = build_query([skater_2, skater]).send(:cache_key)

      expect(key_a).to eq(key_b)
    end
  end
end
