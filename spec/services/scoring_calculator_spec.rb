# spec/services/scoring_calculator_spec.rb
require "rails_helper"

RSpec.describe ScoringCalculator do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }

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

  def build_calculator(scorings)
    described_class.new(scorings)
  end

  def build_stat(goals: 0, assists: 0)
    game = instance_double(League::Game, start_time: 1.day.ago)
    build(:pwhl_skater_stat, league: league, league_game: nil, goals: goals, assists: assists).tap do |stat|
      allow(stat).to receive(:league_game).and_return(game)
    end
  end

  describe "#calculate" do
    let(:calculator) { build_calculator(skater_scorings) }

    context "with record inputs" do
      it "returns 0 for empty records" do
        expect(calculator.calculate([], :skater)).to eq(0)
      end

      it "returns 0 when no scoring rules exist for position" do
        expect(calculator.calculate([build_stat(goals: 5)], :goalie)).to eq(0)
      end

      it "calculates score for a single record" do
        calculator.calculate([build_stat(goals: 1, assists: 1)], :skater)
        expect(calculator.calculate([build_stat(goals: 1, assists: 1)], :skater)).to eq(5.0)
      end

      it "sums scores across multiple records" do
        stats = [
          build_stat(goals: 2),
          build_stat(assists: 3),
        ]
        expect(calculator.calculate(stats, :skater)).to eq(12.0)
      end

      it "applies correct weights per field" do
        expect(calculator.calculate([build_stat(goals: 1, assists: 2)], :skater)).to eq(7.0)
      end
    end

    context "with hash inputs" do
      it "returns 0 for empty hash array" do
        expect(calculator.calculate([], :skater)).to eq(0)
      end

      it "returns 0 when no scoring rules exist for position" do
        expect(calculator.calculate([{ goals: 5 }], :goalie)).to eq(0)
      end

      it "calculates score for a single hash" do
        expect(calculator.calculate([{ goals: 1, assists: 1 }], :skater)).to eq(5.0)
      end

      it "sums scores across multiple hashes" do
        inputs = [
          { goals: 2 },
          { assists: 3 },
        ]
        expect(calculator.calculate(inputs, :skater)).to eq(12.0)
      end

      it "applies correct weights per field" do
        expect(calculator.calculate([{ goals: 1, assists: 2 }], :skater)).to eq(7.0)
      end

      it "returns 0 for unrecognised fields" do
        expect(calculator.calculate([{ shots: 5 }], :skater)).to eq(0)
      end
    end

    context "with goalie scorings" do
      let(:calculator) { build_calculator(goalie_scorings) }

      def build_goalie_stat(saves: 0, win: false, shutout: false)
        game = instance_double(League::Game, start_time: 1.day.ago)
        build(:pwhl_goalie_stat, league: league, saves: saves, win: win, shutout: shutout).tap do |stat|
          allow(stat).to receive(:league_game).and_return(game)
        end
      end

      it "calculates score for a goalie record" do
        expect(calculator.calculate([build_goalie_stat(saves: 20, win: true, shutout: true)], :goalie)).to eq(13.0)
      end

      it "calculates score for a goalie hash" do
        expect(calculator.calculate([{ saves: 20, win: true, shutout: true }], :goalie)).to eq(13.0)
      end
    end
  end
end
