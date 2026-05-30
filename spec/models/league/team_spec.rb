require "rails_helper"

RSpec.describe League::Team, type: :model do
  it { should belong_to(:league) }

  it { should have_many(:players) }
  it { should have_many(:away_games) }
  it { should have_many(:home_games) }

  describe ".short_codes_by_league" do
    let(:league) { create(:league) }
    let!(:team_a) { create(:league_team, league: league, short_code: "AAA") }
    let!(:team_b) { create(:league_team, league: league, short_code: "BBB") }
    let!(:other)  { create(:league_team, short_code: "CCC") }

    it "returns a hash of id => short_code for the given league" do
      result = League::Team.short_codes_by_league(league.id)
      expect(result).to eq({ team_a.id => "AAA", team_b.id => "BBB" })
    end

    it "does not include teams from other leagues" do
      result = League::Team.short_codes_by_league(league.id)
      expect(result.values).not_to include("CCC")
    end
  end

  describe "#todays_game" do
    let(:league) { create(:league, :pwhl) }
    let(:team) { create(:league_team, league: league) }
    let(:other_team) { create(:league_team, league: league) }

    it "returns today's game when the team is the home team" do
      game = create(:league_game, league: league, home_team: team, away_team: other_team,
                    start_time: Time.current.noon)
      expect(team.todays_game.id).to eq(game.id)
    end

    it "returns today's game when the team is the away team" do
      game = create(:league_game, league: league, home_team: other_team, away_team: team,
                    start_time: Time.current.noon)
      expect(team.todays_game.id).to eq(game.id)
    end

    it "returns nil when there is no game today" do
      create(:league_game, league: league, home_team: team, away_team: other_team,
             start_time: 1.day.from_now.noon)
      expect(team.todays_game).to be_nil
    end

    it "does not return games from other teams" do
      create(:league_game, league: league, home_team: other_team, away_team: other_team,
             start_time: Time.current.noon)
      expect(team.todays_game).to be_nil
    end
  end

  describe "#next_game" do
    let(:league) { create(:league, :pwhl) }
    let(:team) { create(:league_team, league: league) }
    let(:other_team) { create(:league_team, league: league) }

    it "returns the next upcoming game when the team is the home team" do
      game = create(:league_game, league: league, home_team: team, away_team: other_team,
                    start_time: 2.days.from_now.noon)
      expect(team.next_game.id).to eq(game.id)
    end

    it "returns the next upcoming game when the team is the away team" do
      game = create(:league_game, league: league, home_team: other_team, away_team: team,
                    start_time: 2.days.from_now.noon)
      expect(team.next_game.id).to eq(game.id)
    end

    it "returns the earliest upcoming game when multiple exist" do
      sooner = create(:league_game, league: league, home_team: team, away_team: other_team,
                      start_time: 2.days.from_now.noon)
      create(:league_game, league: league, home_team: team, away_team: other_team,
             start_time: 5.days.from_now.noon)
      expect(team.next_game.id).to eq(sooner.id)
    end

    it "does not return today's game" do
      create(:league_game, league: league, home_team: team, away_team: other_team,
             start_time: Time.current.noon)
      expect(team.next_game).to be_nil
    end

    it "does not return games from other teams" do
      create(:league_game, league: league, home_team: other_team, away_team: other_team,
             start_time: 2.days.from_now.noon)
      expect(team.next_game).to be_nil
    end
  end

  describe "cache invalidation" do
    let(:team) { create(:league_team) }

    it "invalidates the short code cache when short_code changes" do
      expect(Rails.cache).to receive(:delete).with("league/#{team.league_id}/team_short_codes")
      team.update!(short_code: "NEW")
    end

    it "does not invalidate the cache when other attributes change" do
      expect(Rails.cache).not_to receive(:delete)
      team.update!(name: "New Name")
    end
  end
end
