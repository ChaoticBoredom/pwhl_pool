require "rails_helper"

RSpec.describe Pwhl::GameData do
  include_context "pwhl teams"

  subject(:service) { described_class.new }

  describe "#update_live_game" do
    # Game 338: BOS (1) vs OTT (5), playoff, early 1st period
    # Goalie section has split entries for the visitor goalie (penalty relief)
    # This VCR was manually built as the state is super transient, it WILL NOT RE_RECORD!!!
    context "with game 338 (playoff, in progress — early 1st period)",
            vcr: { cassette_name: "pwhl/game_summary/in_progress_early", record: :none } do
      let!(:game) { create(:league_game, league: pwhl, api_id: "338", season_id: "9") }

      it "does not raise" do
        expect { service.update_live_game(game.id) }.not_to raise_error
      end

      it "updates current_description to a formatted status string" do
        service.update_live_game(game.id)
        # Raw API value is "In Progress (0:00 remaining in 1st)" → should be "1st INT"
        expect(game.reload.current_description).to eq("1st INT")
      end

      it "creates players it hasn't seen before" do
        expect { service.update_live_game(game.id) }.to change(League::Player, :count).by_at_least(1)
      end

      it "creates the starting Boston goalie" do
        service.update_live_game(game.id)
        expect(League::Player.find_by(api_id: "6").name).to eq("Aerin Frankel")
      end

      it "creates goalie stats for both teams" do
        expect { service.update_live_game(game.id) }.to change { Pwhl::GoalieStat.count }.by(4)
      end

      it "creates skater stats for all rostered players" do
        expect { service.update_live_game(game.id) }.to change { Pwhl::SkaterStat.count }.by(38)
      end

      it "associates goalie stats with the correct teams" do
        service.update_live_game(game.id)
        bos = team("1")
        ott = team("5")
        expect(Pwhl::GoalieStat.pluck(:league_team_id).uniq).to match_array([bos.id, ott.id])
      end

      it "associates skater stats with the correct teams" do
        service.update_live_game(game.id)
        bos = team("1")
        ott = team("5")
        expect(Pwhl::SkaterStat.pluck(:league_team_id).uniq).to match_array([bos.id, ott.id])
      end

      it "handles the visitor goalie split-entry correctly (penalty relief)" do
        # OTT goalie Gwyneth Philips (api_id 222) appears twice in the goalies
        # section due to a penalty — should produce one GoalieStat record
        service.update_live_game(game.id)
        ott = team("5")
        expect(
          Pwhl::GoalieStat.where(league_team: ott)
            .joins(:league_player)
            .where(league_players: { api_id: "222" })
            .count
        ).to eq(1)
      end
    end

    context "idempotentency" do
      let!(:game) { create(:league_game, league: pwhl, api_id: "338", season_id: "9") }

      before do
        allow(Connections::ConnectionHelper.pwhl_connection).to receive(:get).
          and_return(double(body: file_fixture("pwhl/game_summary_in_progress_early.json").read))
      end

      it "does not duplicate goalie stats when called twice" do
        service.update_live_game(game.id)
        expect { service.update_live_game(game.id) }.to_not change { Pwhl::GoalieStat.count }
      end

      it "does not duplicate skater stats when called twice" do
        service.update_live_game(game.id)
        expect { service.update_live_game(game.id) }.to_not change { Pwhl::SkaterStat.count }
      end
    end

    # Game 275: VAN (9) vs TOR (6), regular season, 3rd period in progress
    # Has plusminus values as "+1"/"+2" strings for some players
    context "with game 275 (regular season, in progress — 3rd period)",
            vcr: { cassette_name: "pwhl/game_summary/in_progress_3rd", record: :none } do
      let!(:game) { create(:league_game, league: pwhl, api_id: "275", season_id: "8") }

      it "does not raise" do
        expect { service.update_live_game(game.id) }.not_to raise_error
      end

      it "formats the in-progress status string correctly" do
        service.update_live_game(game.id)
        # Raw: "In Progress (10:53 remaining in 3rd)" → "3rd (10:53)"
        expect(game.reload.current_description).to eq("3rd (10:53)")
      end

      it "handles plusminus values with leading plus signs" do
        service.update_live_game(game.id)
        # Claire Dalton (api_id 26) has plusminus "+2" in the cassette
        player  = League::Player.find_by(api_id: "26")
        tor     = team("6")
        stat    = Pwhl::SkaterStat.find_by(league_player: player, league_team: tor)
        expect(stat.plus_minus).to eq(2)
      end

      it "handles negative plusminus values" do
        service.update_live_game(game.id)
        # Madison Samoskevich (api_id 310) has plusminus -1
        player = League::Player.find_by(api_id: "310")
        van    = team("9")
        stat   = Pwhl::SkaterStat.find_by(league_player: player, league_team: van)
        expect(stat.plus_minus).to eq(-1)
      end
    end

    # Game 343: upcoming playoff game — no goalie data, no lineup stats yet
    context "with game 343 (playoff, scheduled — no goalie data)",
            vcr: { cassette_name: "pwhl/game_summary/scheduled_playoff" } do
      let!(:game) { create(:league_game, league: pwhl, api_id: "343", season_id: "9") }

      it "does not raise when the goalies section is absent" do
        expect { service.update_live_game(game.id) }.not_to raise_error
      end

      it "does not create any goalie stats" do
        expect { service.update_live_game(game.id) }.not_to change(Pwhl::GoalieStat, :count)
      end
    end

    # Game 286: completed regular season game
    context "with game 286 (regular season, final)",
            vcr: { cassette_name: "pwhl/game_summary/final_regular" } do
      let!(:game) { create(:league_game, league: pwhl, api_id: "286", season_id: "8") }

      it "does not raise" do
        expect { service.update_live_game(game.id) }.not_to raise_error
      end

      it "creates goalie stats for both teams" do
        expect { service.update_live_game(game.id) }.to change { Pwhl::GoalieStat.count }.by(4)
      end

      it "creates skater stats for both teams" do
        expect { service.update_live_game(game.id) }.to change { Pwhl::SkaterStat.count }.by(38)
      end
    end
  end

  describe "#update_game_data" do
    let(:base_game_data) do
      {
        "id" => "2001",
        "season_id" => "4",
        "home_team" => "1",
        "visiting_team" => "5",
        "home_goal_count" => "2",
        "visiting_goal_count" => "1",
        "started" => "0",
        "pending_final" => "0",
        "final" => "0",
        "GameDateISO8601" => "2025-01-15T19:00:00-05:00",
      }
    end

    context "when creating a new game" do
      it "creates a League::Game record" do
        expect { service.update_game_data(base_game_data) }.to change(League::Game, :count).by(1)
      end

      it "assigns the correct home and away teams" do
        service.update_game_data(base_game_data)
        g = League::Game.find_by(api_id: "2001")
        expect(g.home_team).to eq(team("1"))
        expect(g.away_team).to eq(team("5"))
      end

      it "assigns scores" do
        service.update_game_data(base_game_data)
        g = League::Game.find_by(api_id: "2001")
        expect(g.home_team_score).to eq(2)
        expect(g.away_team_score).to eq(1)
      end
    end

    context "when updating an existing game" do
      before { service.update_game_data(base_game_data) }

      it "does not create a duplicate record" do
        updated_data = base_game_data.merge("home_goal_count" => "3")
        expect { service.update_game_data(updated_data) }.not_to change(League::Game, :count)
      end

      it "updates the score" do
        service.update_game_data(base_game_data.merge("home_goal_count" => "3"))
        expect(League::Game.find_by(api_id: "2001").home_team_score).to eq(3)
      end
    end

    context "when a game_id is provided" do
      let!(:game) { create(:league_game, league: pwhl, api_id: "9999", season_id: "4") }

      it "updates that specific game rather than finding or creating by api_id" do
        service.update_game_data(base_game_data, game.id)
        expect(game.reload.home_team_score).to eq(2)
      end

      it "does not create a new game record" do
        expect { service.update_game_data(base_game_data, game.id) }.not_to change(League::Game, :count)
      end
    end

    describe "status mapping" do
      {
        "scheduled" => { "started" => "0", "pending_final" => "0", "final" => "0" },
        "in_progress" => { "started" => "1", "pending_final" => "0", "final" => "0" },
        "pending_final" => { "started" => "1", "pending_final" => "1", "final" => "0" },
        "final" => { "started" => "1", "pending_final" => "0", "final" => "1" },
      }.each do |expected_status, status_fields|
        it "maps status codes #{status_fields.values.join('/')} to :#{expected_status}" do
          service.update_game_data(base_game_data.merge(status_fields))
          expect(League::Game.find_by(api_id: "2001").status).to eq(expected_status)
        end
      end
    end

    describe "start_time parsing" do
      it "prefers GameDateISO8601 when present" do
        service.update_game_data(base_game_data)
        expect(League::Game.find_by(api_id: "2001").start_time)
          .to eq(DateTime.parse("2025-01-15T19:00:00-05:00"))
      end

      it "falls back to date_played + schedule_time + timezone_short" do
        data = base_game_data.except("GameDateISO8601").merge(
          "date_played" => "2025-01-15",
          "schedule_time" => "19:00:00",
          "timezone_short" => "EST",
        )
        expect { service.update_game_data(data) }.not_to raise_error
        expect(League::Game.find_by(api_id: "2001").start_time).not_to be_nil
      end
    end
  end

  describe "#update_player_game_data" do
    # api_ids chosen to not collide with players created by update_live_game tests
    let!(:skater) { create(:pwhl_skater, league: pwhl, api_id: "9001") }
    let!(:goalie) { create(:pwhl_goalie, league: pwhl, api_id: "9002") }
    let!(:game) { create(:league_game, league: pwhl, api_id: "338", season_id: "9") }

    context "when game_data is provided (rake path — no HTTP call)" do
      let(:skater_data) do
        {
          "id" => game.api_id,
          "player_team" => "1",
          "goals" => "1",
          "assists" => "2",
          "pim" => "2",
          "shots" => "4",
          "hits" => "1",
          "ice_time_minutes_seconds" => "18:32",
          "power_play_goals" => "1",
          "short_handed_goals" => "0",
          "shots_blocked_by_player" => "2",
          "plusminus" => "2",
          "faceoffs_taken" => "10",
          "faceoffs_won" => "6",
          "game_winning_goals" => "1",
        }
      end

      let(:goalie_data) do
        {
          "id" => game.api_id,
          "player_team" => "1",
          "goals" => "0",
          "assists" => "1",
          "win" => "1",
          "shutout" => "0",
          "saves" => "28",
          "goals_against" => "2",
          "shots_against" => "30",
          "pim" => "0",
          "seconds_played" => "3600",
        }
      end

      it "does not make any HTTP requests" do
        stub = stub_request(:any, /.*/)
        service.update_player_game_data(skater.id, game.id, skater_data)
        expect(stub).not_to have_been_requested
      end

      it "creates a skater stat record" do
        expect { service.update_player_game_data(skater.id, game.id, skater_data) }.
          to change(Pwhl::SkaterStat, :count).by(1)
      end

      it "creates a goalie stat record" do
        expect { service.update_player_game_data(goalie.id, game.id, goalie_data) }.
          to change(Pwhl::GoalieStat, :count).by(1)
      end

      it "maps skater stats correctly" do
        service.update_player_game_data(skater.id, game.id, skater_data)
        stat = Pwhl::SkaterStat.find_by(league_player: skater, league_game: game)

        expect(stat.goals).to eq(1)
        expect(stat.assists).to eq(2)
        expect(stat.time_on_ice).to eq(18.minutes + 32.seconds)
        expect(stat.game_winning_goals).to eq(1)
      end

      it "maps goalie stats correctly" do
        service.update_player_game_data(goalie.id, game.id, goalie_data)
        stat = Pwhl::GoalieStat.find_by(league_player: goalie, league_game: game)

        expect(stat.win).to be true
        expect(stat.saves).to eq(28)
        expect(stat.time_on_ice).to eq(3600.seconds)
      end

      it "assigns the team from player_team api_id" do
        service.update_player_game_data(skater.id, game.id, skater_data)
        stat = Pwhl::SkaterStat.find_by(league_player: skater, league_game: game)
        expect(stat.league_team).to eq(team("1"))
      end

      it "is idempotent — calling twice does not duplicate records" do
        service.update_player_game_data(skater.id, game.id, skater_data)
        expect { service.update_player_game_data(skater.id, game.id, skater_data) }.
          not_to change { Pwhl::SkaterStat.where(league_player: skater, league_game: game).count }
      end
    end

    context "when game_data is nil (standalone HTTP path)" do
      context "for a skater", vcr: { cassette_name: "pwhl/player/skater_gamebygame" } do
        let!(:skater) { create(:pwhl_skater, league: pwhl, api_id: "58") }

        it "fetches and creates a stat record" do
          expect { service.update_player_game_data(skater.id, game.id) }
            .to change(Pwhl::SkaterStat, :count).by(1)
        end
      end

      context "for a goalie", vcr: { cassette_name: "pwhl/player/goalie_gamebygame" } do
        let!(:goalie) { create(:pwhl_goalie, league: pwhl, api_id: "6") }

        it "fetches and creates a stat record" do
          expect { service.update_player_game_data(goalie.id, game.id) }
            .to change(Pwhl::GoalieStat, :count).by(1)
        end
      end
    end
  end

  describe "#format_game_status_string" do
    subject(:format) { service.send(:format_game_status_string, input) }

    context "with intermission strings" do
      {
        "In Progress (0:00 remaining in 1st)" => "1st INT",
        "In Progress (0:00 remaining in 2nd)" => "2nd INT",
        "In Progress (0:00 remaining in 3rd)" => "3rd INT",
        "In Progress (0:00 remaining in OT)" => "OT INT",
        "In Progress (0:00 remaining in 1st OT)" => "1st OT INT",
        "In Progress (0:00 remaining in 2nd OT)" => "2nd OT INT",
        "In Progress (0:00 remaining in 3rd OT)" => "3rd OT INT",
      }.each do |input_str, expected|
        context "with #{input_str.inspect}" do
          let(:input) { input_str }
          it { is_expected.to eq(expected) }
        end
      end
    end

    context "with in-progress strings" do
      {
        "In Progress (14:22 remaining in 1st Period)" => "1st (14:22)",
        "In Progress (10:53 remaining in 3rd)" => "3rd (10:53)",
        "In Progress (0:01 remaining in 3rd Period)" => "3rd (0:01)",
        "In Progress (5:00 remaining in OT)" => "OT (5:00)",
        "In Progress (3:17 remaining in 2nd OT)" => "2OT (3:17)",
        "In Progress (0:00 remaining in 1st)" => "1st INT",
      }.each do |input_str, expected|
        context "with #{input_str.inspect}" do
          let(:input) { input_str }
          it { is_expected.to eq(expected) }
        end
      end
    end

    context "with shootout strings" do
      {
        "In Progress (Shootout)" => "SO (In Progress)",
        "Shootout" => "SO (In Progress)",
      }.each do |input_str, expected|
        context "with #{input_str.inspect}" do
          let(:input) { input_str }
          it { is_expected.to eq(expected) }
        end
      end
    end

    context "with an unrecognised string" do
      let(:input) { "Final" }
      it "returns the string unchanged" do
        is_expected.to eq("Final")
      end
    end
  end

  describe "#update_goalie_data" do
    let(:rec) { Pwhl::GoalieStat.new }

    context "win/shutout flag mapping" do
      it "maps '1' to true for win" do
        result = service.send(:update_goalie_data, rec, { "win" => "1", "shutout" => "0" })
        expect(result.win).to be true
      end

      it "maps '0' to false for win" do
        result = service.send(:update_goalie_data, rec, { "win" => "0", "shutout" => "0" })
        expect(result.win).to be false
      end

      it "maps '1' to true for shutout" do
        result = service.send(:update_goalie_data, rec, { "win" => "0", "shutout" => "1" })
        expect(result.shutout).to be true
      end

      it "maps '0' to false for shutout" do
        result = service.send(:update_goalie_data, rec, { "win" => "0", "shutout" => "0" })
        expect(result.shutout).to be false
      end
    end

    context "game_started" do
      it "is true when period_start is '1st'" do
        result = service.send(:update_goalie_data, rec, { "period_start" => "1st" })
        expect(result.game_started).to be true
      end

      it "is false when period_start is a later period" do
        result = service.send(:update_goalie_data, rec, { "period_start" => "2nd" })
        expect(result.game_started).to be false
      end

      it "is false when period_start is absent (gamebygame path)" do
        result = service.send(:update_goalie_data, rec, {})
        expect(result.game_started).to be false
      end
    end

    context "time_on_ice" do
      it "reads from 'seconds' (game summary path)" do
        result = service.send(:update_goalie_data, rec, { "seconds" => 1200 })
        expect(result.time_on_ice).to eq(1200.seconds)
      end

      it "falls back to 'seconds_played' (gamebygame path)" do
        result = service.send(:update_goalie_data, rec, { "seconds_played" => "2700" })
        expect(result.time_on_ice).to eq(2700.seconds)
      end

      it "defaults to 0 when neither key is present" do
        result = service.send(:update_goalie_data, rec, {})
        expect(result.time_on_ice).to eq(0.seconds)
      end
    end

    context "penalty_minutes" do
      it "converts pim integer minutes to a duration" do
        result = service.send(:update_goalie_data, rec, { "pim" => "4" })
        expect(result.penalty_minutes).to eq(4.minutes)
      end
    end

    context "defaults when data is sparse (early live game)" do
      subject(:result) { service.send(:update_goalie_data, rec, {}) }
      it { expect(result.goals).to eq(0) }
      it { expect(result.assists).to eq(0) }
      it { expect(result.saves).to eq(0) }
      it { expect(result.goals_against).to eq(0) }
      it { expect(result.shots_against).to eq(0) }
    end
  end

  describe "#update_skater_data" do
    let(:rec) { Pwhl::SkaterStat.new }

    context "plus_minus field name inconsistency" do
      it "prefers 'plusminus' (game summary) over 'plus_minus' (gamebygame)" do
        data = { "plusminus" => "3", "plus_minus" => "1" }
        expect(service.send(:update_skater_data, rec, data).plus_minus).to eq(3)
      end

      it "falls back to 'plus_minus' when 'plusminus' is absent" do
        data = { "plus_minus" => "-2" }
        expect(service.send(:update_skater_data, rec, data).plus_minus).to eq(-2)
      end

      it "handles string values with a leading plus sign" do
        data = { "plusminus" => "+2" }
        expect(service.send(:update_skater_data, rec, data).plus_minus).to eq(2)
      end

      it "handles integer zero" do
        data = { "plusminus" => 0 }
        expect(service.send(:update_skater_data, rec, data).plus_minus).to eq(0)
      end
    end

    context "faceoff field name inconsistency" do
      it "prefers 'faceoffs_taken' over 'faceoff_attempts'" do
        data = { "faceoffs_taken" => "10", "faceoff_attempts" => "5" }
        expect(service.send(:update_skater_data, rec, data).faceoffs_taken).to eq(10)
      end

      it "falls back to 'faceoff_attempts'" do
        data = { "faceoff_attempts" => "8" }
        expect(service.send(:update_skater_data, rec, data).faceoffs_taken).to eq(8)
      end

      it "prefers 'faceoffs_won' over 'faceoff_wins'" do
        data = { "faceoffs_won" => "6", "faceoff_wins" => "3" }
        expect(service.send(:update_skater_data, rec, data).faceoffs_won).to eq(6)
      end

      it "falls back to 'faceoff_wins'" do
        data = { "faceoff_wins" => "4" }
        expect(service.send(:update_skater_data, rec, data).faceoffs_won).to eq(4)
      end
    end

    context "game_winning_goal field name inconsistency" do
      it "prefers 'game_winning_goals' (gamebygame) over 'game_winning_goal' (game summary)" do
        data = { "game_winning_goals" => "1", "game_winning_goal" => "0" }
        expect(service.send(:update_skater_data, rec, data).game_winning_goals).to eq(1)
      end

      it "falls back to 'game_winning_goal'" do
        data = { "game_winning_goal" => "1" }
        expect(service.send(:update_skater_data, rec, data).game_winning_goals).to eq(1)
      end
    end

    context "time_on_ice" do
      it "parses MM:SS format correctly" do
        data = { "ice_time_minutes_seconds" => "18:32" }
        expect(service.send(:update_skater_data, rec, data).time_on_ice)
          .to eq(18.minutes + 32.seconds)
      end

      it "handles zero ice time" do
        data = { "ice_time_minutes_seconds" => "0:00" }
        expect(service.send(:update_skater_data, rec, data).time_on_ice).to eq(0)
      end

      it "defaults to zero when field is absent" do
        expect(service.send(:update_skater_data, rec, {}).time_on_ice).to eq(0)
      end
    end

    context "penalty_minutes" do
      it "converts pim to a duration" do
        data = { "pim" => "4" }
        expect(service.send(:update_skater_data, rec, data).penalty_minutes).to eq(4.minutes)
      end
    end

    context "defaults when data is sparse" do
      subject(:result) { service.send(:update_skater_data, rec, {}) }
      it { expect(result.goals).to eq(0) }
      it { expect(result.assists).to eq(0) }
      it { expect(result.shots).to eq(0) }
      it { expect(result.hits).to eq(0) }
      it { expect(result.power_play_goals).to eq(0) }
      it { expect(result.short_handed_goals).to eq(0) }
      it { expect(result.shots_blocked).to eq(0) }
    end
  end

  describe "#parse_time" do
    {
      "18:32" => 18.minutes + 32.seconds,
      "0:00"  => 0,
      "0:45"  => 45.seconds,
      "60:00" => 60.minutes,
      "49:07" => 49.minutes + 7.seconds,
    }.each do |input, expected|
      it "parses #{input.inspect} correctly" do
        expect(service.send(:parse_time, input)).to eq(expected)
      end
    end
  end

  describe "#find_or_create_player" do
    let(:player_data) do
      { "player_id" => "999", "first_name" => "Jane", "last_name" => "Doe" }
    end
    let(:boston) { team("1") }

    it "creates a new player when one does not exist" do
      expect {
        service.send(:find_or_create_player, player_data, "skater", boston)
      }.to change(League::Player, :count).by(1)
    end

    it "returns the existing player on a second call" do
      p1 = service.send(:find_or_create_player, player_data, "skater", boston)
      p2 = service.send(:find_or_create_player, player_data, "skater", boston)
      expect(p1.id).to eq(p2.id)
    end

    it "sets the player name from first_name + last_name" do
      player = service.send(:find_or_create_player, player_data, "skater", boston)
      expect(player.name).to eq("Jane Doe")
    end

    it "assigns the correct position" do
      player = service.send(:find_or_create_player, player_data, "goalie", boston)
      expect(player.position).to eq("goalie")
    end

    it "assigns the league" do
      player = service.send(:find_or_create_player, player_data, "skater", boston)
      expect(player.league).to eq(pwhl)
    end

    it "assigns the current team" do
      player = service.send(:find_or_create_player, player_data, "skater", boston)
      expect(player.current_team).to eq(boston)
    end
  end
end
