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

  def build_query(player_ids: nil, players: nil, season_id: self.season_id)
    described_class.new(player_ids: player_ids, players: players, season_id: season_id)
  end

  describe "#records" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 14:00:00"), &ex) }

    context "with player_ids: input" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "returns records keyed by league_player_id" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(player_ids: [skater.id]).records
        expect(result).to have_key(skater.id)
      end

      it "deduplicates when the same id appears multiple times" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(player_ids: [skater.id, skater.id]).records
        expect(result[skater.id].length).to eq(1)
      end
    end

    context "with players: League::Player input" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "returns records keyed by league_player_id" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(players: [skater]).records
        expect(result).to have_key(skater.id)
      end

      it "uses the player id directly" do
        skater_stat = create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(players: [skater]).records
        expect(result[skater.id]).to include(skater_stat)
      end
    end

    context "with players: Pool::TeamPlayer input" do
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

        result = build_query(players: [team_player]).records
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

        result = build_query(players: [team_player, team_player_2]).records
        expect(result[skater.id].length).to eq(1)
      end
    end

    context "with an unsupported player type" do
      it "raises ArgumentError" do
        expect { build_query(players: ["not_a_player"]).records }
          .to raise_error(ArgumentError, /Unsupported player type/)
      end
    end

    context "when both player_ids: and players: are provided" do
      let(:skater)   { create(:pwhl_skater, league: league) }
      let(:skater_2) { create(:pwhl_skater, league: league) }

      it "uses player_ids: and ignores players:" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = described_class.new(
          player_ids: [skater.id],
          players: [skater_2],
          season_id: season_id
        ).records

        expect(result).to have_key(skater.id)
        expect(result).not_to have_key(skater_2.id)
      end
    end

    context "when neither player_ids: nor players: are provided" do
      it "raises ArgumentError" do
        expect { described_class.new(season_id: season_id) }
          .to raise_error(ArgumentError, /Must provide either player_ids: or players:/)
      end
    end

    context "with empty input" do
      it "returns an empty hash with player_ids: []" do
        expect(build_query(player_ids: []).records).to eq({})
      end

      it "returns an empty hash with players: []" do
        expect(build_query(players: []).records).to eq({})
      end
    end

    context "season scoping" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "includes records from the given season" do
        stat = create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(player_ids: [skater.id]).records
        expect(result[skater.id]).to include(stat)
      end

      it "excludes records from a different season" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago, season_id: "2024-2025"))

        result = build_query(player_ids: [skater.id]).records
        expect(result).not_to have_key(skater.id)
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

        result = build_query(player_ids: [skater.id], season_id: "2023-2024").records
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

        result = build_query(player_ids: [skater.id, goalie.id]).records
        expect(result[skater.id].first).to be_a(Pwhl::SkaterStat)
      end

      it "returns goalie stats under the goalie's league_player_id" do
        create(:pwhl_goalie_stat,
          league: league,
          league_player: goalie,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(player_ids: [skater.id, goalie.id]).records
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

        result = build_query(player_ids: [skater.id, goalie.id]).records
        expect(result.keys).to contain_exactly(skater.id, goalie.id)
      end
    end

    context "historical vs today split" do
      let(:skater) { create(:pwhl_skater, league: league) }

      it "includes a game from yesterday" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))

        result = build_query(player_ids: [skater.id]).records
        expect(result[skater.id].length).to eq(1)
      end

      it "includes a game from today" do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.hour.ago))

        result = build_query(player_ids: [skater.id]).records
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

        result = build_query(player_ids: [skater.id]).records
        expect(result[skater.id].length).to eq(2)
      end
    end

    context "caching" do
      let(:skater) { create(:pwhl_skater, league: league) }

      before(:each) do
        create(:pwhl_skater_stat,
          league: league,
          league_player: skater,
          league_game: create_game(start_time: 1.day.ago))
      end

      it "writes historical records to cache on first call" do
        expect(Rails.cache).to receive(:write).at_least(:once)
        build_query(player_ids: [skater.id]).records
      end

      it "reads from cache on subsequent calls without writing" do
        allow(Rails.cache).to receive(:read).and_return([])
        expect(Rails.cache).to_not receive(:write)
        build_query(player_ids: [skater.id]).records
      end
    end
  end

  describe "#player_cache_key" do
    let(:skater) { create(:pwhl_skater, league: league) }

    it "produces different cache keys across days" do
      key_today = build_query(player_ids: [skater.id]).send(:player_cache_key, skater.id)
      key_tomorrow = travel_to(1.day.from_now) do
        build_query(player_ids: [skater.id]).send(:player_cache_key, skater.id)
      end

      expect(key_today).not_to eq(key_tomorrow)
    end

    it "produces different cache keys for different player ids" do
      skater_2 = create(:pwhl_skater, league: league)

      key_one = build_query(player_ids: [skater.id]).send(:player_cache_key, skater.id)
      key_two = build_query(player_ids: [skater.id]).send(:player_cache_key, skater_2.id)

      expect(key_one).not_to eq(key_two)
    end
  end
end
