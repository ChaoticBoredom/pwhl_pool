require "rails_helper"

RSpec.describe Reports::ScoreSummaryService do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league, season_id: "9") }
  let(:admin) { create(:user) }

  let!(:goals_scoring) { create(:pool_scoring, :skater, :goals, value: 2.0, pool: pool) }
  let!(:assists_scoring) { create(:pool_scoring, :skater, :assists, value: 1.0, pool: pool) }
  let!(:saves_scoring) { create(:pool_scoring, :goalie, :saves, value: 0.1, pool: pool) }

  let(:skater) { create(:pwhl_skater, league: league) }
  let(:dropped_skater) { create(:pwhl_skater, league: league) }
  let(:goalie) { create(:pwhl_goalie, league: league) }

  let!(:skater_box) { create(:pool_box, pool: pool, league_player_ids: [skater.id, dropped_skater.id]) }
  let!(:goalie_box) { create(:pool_box, pool: pool, league_player_ids: [goalie.id]) }

  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:owner) { pool_team.owner }
  let(:other_pool_team) { create(:pool_team, pool: pool) }

  let!(:dropped_tp) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: dropped_skater,
      pool_box: skater_box,
      added_at: Time.zone.parse("2026-01-01 06:00:00"),
      dropped_at: Time.zone.parse("2026-01-15 06:00:00")
    )
  end

  let!(:skater_tp) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: skater,
      pool_box: skater_box,
      added_at: Time.zone.parse("2026-01-15 06:00:00"),
    )
  end

  let!(:goalie_tp) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: goalie,
      pool_box: goalie_box,
      added_at: Time.zone.parse("2026-01-01 06:00:00"),
    )
  end

  let!(:skater_other_tp) do
    create(:pool_team_player,
      pool_team: other_pool_team,
      league_player: skater,
      pool_box: skater_box,
      added_at: Time.zone.parse("2026-01-01 06:00:00"),
    )
  end

  let!(:game_jan) do
    create(:league_game,
      :final,
      league: league,
      season_id: "9",
      start_time: Time.zone.parse("2026-01-10 19:00:00"),
    )
  end

  let!(:game_feb) do
    create(:league_game,
      :final,
      league: league,
      season_id: "9",
      start_time: Time.zone.parse("2026-02-10 19:00:00"),
    )
  end

  let!(:skater_stat_jan) do
    create(:pwhl_skater_stat,
      league: league,
      league_player: skater,
      league_game: game_jan,
      goals: 2,
      assists: 1,
    )
  end

  let!(:skater_stat_feb) do
    create(:pwhl_skater_stat,
      league: league,
      league_player: skater,
      league_game: game_feb,
      goals: 0,
      assists: 3,
    )
  end

  let!(:dropped_skater_stat_jan) do
    create(:pwhl_skater_stat,
      league: league,
      league_player: dropped_skater,
      league_game: game_jan,
      goals: 1,
      assists: 2,
    )
  end

  let!(:dropped_skater_stat_feb) do
    create(:pwhl_skater_stat,
      league: league,
      league_player: dropped_skater,
      league_game: game_feb,
      goals: 3,
      assists: 0,
    )
  end

  let!(:goalie_stat_jan) do
    create(:pwhl_goalie_stat,
      :win,
      league: league,
      league_player: goalie,
      league_game: game_jan,
      saves: 20,
    )
  end

  let(:full_range) { Time.zone.parse("2026-01-01").beginning_of_day..Time.zone.parse("2026-03-1").end_of_day }

  def build_service(range: full_range, breakdowns: [], period: nil)
    described_class.new(pool, range, breakdowns: breakdowns, period: period)
  end

  describe "#call" do
    let(:result) { build_service.call }
    let(:team_result) { result.find { |t| t[:id] == pool_team.id } }
    let(:other_team_result) { result.find { |t| t[:id] == other_pool_team.id } }

    it "returns one entry per pool team" do
      expect(result.length).to eq(2)
      expect(result.map { |t| t[:id] }).to match_array([pool_team.id, other_pool_team.id])
    end

    it "includes team id and name" do
      expect(team_result[:id]).to eq(pool_team.id)
      expect(team_result[:team_name]).to eq(pool_team.team_name)
    end

    it "calculates total_score across all players" do
      expect(team_result[:total_score]).to be_within(0.01).of(9.0)
      expect(other_team_result[:total_score]).to be_within(0.01).of(8.0)
    end

    it "does not include by_category without breakdown" do
      expect(team_result).to_not have_key(:by_category)
    end

    it "does not include by_player without breakdown" do
      expect(team_result).to_not have_key(:by_player)
    end

    it "does not include periods without period param" do
      expect(team_result).to_not have_key(:periods)
    end

    context "with by_category breakdown" do
      let(:result) { build_service(breakdowns: ["by_category"]).call }

      it "includes by_category on team" do
        expect(team_result).to have_key(:by_category)
      end

      [
        ["goals", 2.0, 4.0],
        ["assists", 5.0, 4.0],
        ["saves", 2.0, 0.0],
      ].each do |field, team_val, other_team_val|
        it "sums #{field} across all players" do
          expect(team_result[:by_category][field]).to be_within(0.01).of(team_val)
          expect(other_team_result[:by_category][field]).to be_within(0.01).of(other_team_val)
        end
      end
    end

    context "with by_player breakdown" do
      let(:result) { build_service(breakdowns: ["by_player"]).call }

      it "includes by_player on team" do
        expect(team_result).to have_key(:by_player)
      end

      it "includes all team players including dropped" do
        expect(team_result[:by_player].length).to eq(3)
        expect(other_team_result[:by_player].length).to eq(1)
      end

      it "includes player ids" do
        expect(team_result[:by_player].map { |p| p[:league_player_id] }).to match_array([
          goalie.id,
          skater.id,
          dropped_skater.id,
        ])
        expect(other_team_result[:by_player].map { |p| p[:league_player_id] }).to match_array([skater.id])
      end

      it "includes player names" do
        expect(team_result[:by_player].map { |p| p[:name] }).to match_array([
          goalie.name,
          skater.name,
          dropped_skater.name,
        ])
        expect(other_team_result[:by_player].map { |p| p[:name] }).to match_array([skater.name])
      end

      it "includes 'dropped_at' for dropped players" do
        dropped_player = team_result[:by_player].find { |p| p[:league_player_id] == dropped_skater.id }
        expect(dropped_player[:dropped_at]).to be_within(1.second).of(dropped_tp.dropped_at)
      end

      it "does not include by_category on players without full_breakdown" do
        expect(team_result[:by_player].first).to_not have_key(:by_category)
      end
    end

    context "with full_breakdown breakdown" do
      let(:result) { build_service(breakdowns: ["full_breakdown"]).call }

      it "includes by_category on each player" do
        expect(team_result[:by_player].map { |p| p[:by_category] }).to all(have_key("goals"))
      end

      [
        ["team_result", "skater", "goals", 0.0],
        ["team_result", "skater", "assists", 3.0],
        ["team_result", "dropped_skater", "goals", 2.0],
        ["team_result", "dropped_skater", "assists", 2.0],
        ["team_result", "goalie", "saves", 2.0],
        ["other_team_result", "skater", "goals", 4.0],
      ].each do |result_name, player_name, field, value|
        it "calculates correct #{field} for player" do
          test_player = send(result_name)[:by_player].find { |p| p[:league_player_id] == send(player_name).id }
          expect(test_player[:by_category][field]).to be_within(0.01).of(value)
        end
      end
    end

    context "with date range filtering" do
      let(:jan_only) { Date.new(2026, 1, 1).all_month }
      let(:result) { build_service(range: jan_only).call }

      it "only includes stats within the range" do
        expect(team_result[:total_score]).to be_within(0.01).of(6.0)
        expect(other_team_result[:total_score]).to be_within(0.01).of(5.0)
      end
    end

    context "with period defined" do
      let(:result) { build_service(period: "week").call }

      it "includes periods on team" do
        expect(team_result).to have_key(:periods)
      end

      context "with period: week" do
        let(:result) { build_service(period: "week").call }

        it "generates the correct number of weekly buckets" do
          expect(team_result[:periods].length).to eq(9)
        end

        [
          [Date.new(2026, 1, 10).all_week, 6.0, 5.0],
          [Date.new(2026, 2, 10).all_week, 3.0, 3.0], # Both teams have a single player for the Feb game
        ].each do |week, team_score, other_team_score|
          it "assigns stats to the correct weekly bucket" do
            period = team_result[:periods].find { |p| week.cover?(p[:from].to_date) && week.cover?(p[:to].to_date) }
            other_period = other_team_result[:periods].find { |p| week.cover?(p[:from].to_date) && week.cover?(p[:to].to_date) }
            expect(period[:total_score]).to be_within(0.01).of(team_score)
            expect(other_period[:total_score]).to be_within(0.01).of(other_team_score)
          end
        end

        it "includes total_score on each period" do
          expect(team_result[:periods]).to all(have_key(:total_score))
        end

        it "has all period totals summing to overall total" do
          period_total = team_result[:periods].sum { |p| p[:total_score] }
          expect(period_total).to be_within(0.01).of(team_result[:total_score])
        end
      end

      context "with period: month" do
        let(:result) { build_service(period: "month").call }

        it "generates the correct number of monthly buckets" do
          expect(team_result[:periods].length).to eq(3) # Jan, Feb, March
        end

        it "assigns Jan stats to January bucket" do
          jan = Date.new(2026, 1).all_month
          period = team_result[:periods].find { |p| jan.cover?(p[:from].to_date) && jan.cover?(p[:to].to_date) }
          other_period = other_team_result[:periods].find { |p| jan.cover?(p[:from].to_date) && jan.cover?(p[:to].to_date) }
          expect(period[:total_score]).to be_within(0.01).of(6.0)
          expect(other_period[:total_score]).to be_within(0.01).of(5.0)
        end

        it "assigns Feb stats to February bucket" do
          feb = Date.new(2026, 2).all_month
          period = team_result[:periods].find { |p| feb.cover?(p[:from].to_date) && feb.cover?(p[:to].to_date) }
          other_period = other_team_result[:periods].find { |p| feb.cover?(p[:from].to_date) && feb.cover?(p[:to].to_date) }
          expect(period[:total_score]).to be_within(0.01).of(3.0)
          expect(other_period[:total_score]).to be_within(0.01).of(3.0)
        end
      end

      context "with period: day" do
        let(:result) { build_service(period: "day").call }

        it "generates the correct number of monthly buckets" do
          expect(team_result[:periods].length).to eq(60) # 31 + 28 + 1
        end

        [
          ["team_result", Time.parse("2026-01-10"), 6.0],
          ["other_team_result", Time.parse("2026-01-10"), 5.0],
          ["team_result", Time.parse("2026-02-10"), 3.0],
          ["other_team_result", Time.parse("2026-02-10"), 3.0],
        ].each do |result_name, date, score|
          it "assigns stats to the #{date} bucket for #{result_name}" do
            game_day = send(result_name)[:periods].find { |p| p[:from].to_date == date.to_date }
            expect(game_day[:total_score]).to be_within(0.01).of(score)
          end
        end
      end
    end

    context "with period and by_category breakdown" do
      let(:result) { build_service(period: "month", breakdowns: ["by_category"]).call }

      it "includes by_category on each period" do
        expect(team_result[:periods]).to all(have_key(:by_category))
      end

      [
        ["team_result", Date.new(2026, 1).all_month, "goals", 2.0],
        ["team_result", Date.new(2026, 1).all_month, "assists", 2.0],
        ["team_result", Date.new(2026, 1).all_month, "saves", 2.0],
        ["team_result", Date.new(2026, 2).all_month, "goals", 0.0],
        ["team_result", Date.new(2026, 2).all_month, "assists", 3.0],
        ["team_result", Date.new(2026, 2).all_month, "saves", 0.0],
        ["other_team_result", Date.new(2026, 1).all_month, "goals", 4.0],
        ["other_team_result", Date.new(2026, 1).all_month, "assists", 1.0],
        ["other_team_result", Date.new(2026, 1).all_month, "saves", 0.0],
        ["other_team_result", Date.new(2026, 2).all_month, "goals", 0.0],
        ["other_team_result", Date.new(2026, 2).all_month, "assists", 3.0],
        ["other_team_result", Date.new(2026, 2).all_month, "saves", 0.0],

      ].each do |result_name, month, field, score|
        it "calculates the correct #{field} score per period" do
          period = send(result_name)[:periods].find { |p| month.cover?(p[:from].to_date) && month.cover?(p[:to].to_date) }
          expect(period[:by_category][field]).to be_within(0.01).of(score)
        end
      end
    end
  end
end
