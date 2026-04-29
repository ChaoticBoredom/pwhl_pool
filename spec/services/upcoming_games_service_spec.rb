require "rails_helper"

RSpec.describe UpcomingGamesService do
  let(:league) { create(:league, :pwhl) }
  let(:season_id) { "2025-2026" }

  let(:pool) { create(:pool, league: league, season_id: season_id) }

  let(:home_team) { create(:league_team, league: league) }
  let(:away_team) { create(:league_team, league: league) }

  let(:pool_team) { create(:pool_team, pool: pool) }

  let(:skater) { create(:pwhl_skater, league: league, current_team: home_team) }
  let(:skater_team_player) do
    create(:pool_team_player,
      league_player: skater,
      pool_team: pool_team,
      added_at: 5.months.ago)
  end

  def create_game(start_time: 4.hours.from_now, state: :scheduled)
    create(:league_game,
      state,
      league: league,
      season_id: season_id,
      home_team: home_team,
      away_team: away_team,
      start_time: start_time)
  end

  describe "#player_schedule" do
    around { |ex| travel_to(Time.zone.parse("2026-01-15 13:00"), &ex) }

    context "when passed no team_players" do
      it "returns an empty hash" do
        expect(subject.player_schedule([])).to eq({})
      end
    end


    context "with a game today" do
      [:scheduled, :in_progress, :pending_final, :final].each do |state|
        it "returns a hash with today set when game is in #{state}" do
          todays_game = create_game(start_time: 4.hours.from_now, state: state)
          expect(subject.player_schedule([skater_team_player])).to include(
            skater_team_player.id => hash_including(
              today: have_attributes(id: todays_game.id)
            )
          )
        end

        it "returns a hash with upcoming set to nil" do
          todays_game = create_game(start_time: 4.hours.from_now, state: state)
          expect(subject.player_schedule([skater_team_player])).to include(
            skater_team_player.id => hash_including(upcoming: nil)
          )
        end
      end
    end

    context "with a game in the future" do
      let!(:future_game) { create_game(start_time: 2.days.from_now, state: :scheduled) }

      it "returns a hash with upcoming set" do
        expect(subject.player_schedule([skater_team_player])).to include(
          skater_team_player.id => hash_including(
            upcoming: have_attributes(id: future_game.id)
          )
        )
      end

      it "returns a hash with today set to nil" do
          expect(subject.player_schedule([skater_team_player])).to include(
            skater_team_player.id => hash_including(today: nil)
          )
        end
    end

    context "with games upcoming and today" do
      it "returns a hash with both set" do
        future_game = create_game(start_time: 2.days.from_now, state: :scheduled)
        todays_game = create_game(start_time: 2.hours.ago, state: :in_progress)

        expect(subject.player_schedule([skater_team_player])).to include(
            skater_team_player.id => hash_including(
              today: have_attributes(id: todays_game.id),
              upcoming: have_attributes(id: future_game.id)
            )
          )
      end
    end
  end
end
