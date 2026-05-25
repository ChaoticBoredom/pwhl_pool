# spec/services/scoring_calculator_spec.rb
require "rails_helper"

RSpec.describe ScoringCalculator do
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, league: league) }

  let(:skater_scorings) do
    [
      create(:pool_scoring, :skater, :goals, pool: pool, value: 2),
      create(:pool_scoring, :skater, :assists, pool: pool, value: 1),
    ]
  end

  let(:goalie_scorings) do
    [
      create(:pool_scoring, :goalie, :saves, pool: pool, value: 0.25),
      create(:pool_scoring, :goalie, :wins, pool: pool, value: 3),
      create(:pool_scoring, :goalie, :shutouts, pool: pool, value: 5),
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
        expect(calculator.calculate([build_stat(goals: 1, assists: 1)], :skater)).to eq(3.0)
      end

      it "sums scores across multiple records" do
        stats = [
          build_stat(goals: 2),
          build_stat(assists: 3),
        ]
        expect(calculator.calculate(stats, :skater)).to eq(7.0)
      end

      it "applies correct weights per field" do
        expect(calculator.calculate([build_stat(goals: 1, assists: 2)], :skater)).to eq(4.0)
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
        expect(calculator.calculate([{ goals: 1, assists: 1 }], :skater)).to eq(3.0)
      end

      it "sums scores across multiple hashes" do
        inputs = [
          { goals: 2 },
          { assists: 3 },
        ]
        expect(calculator.calculate(inputs, :skater)).to eq(7.0)
      end

      it "applies correct weights per field" do
        expect(calculator.calculate([{ goals: 1, assists: 2 }], :skater)).to eq(4.0)
      end

      it "returns 0 for unrecognised fields" do
        expect(calculator.calculate([{ shots: 5 }], :skater)).to eq(0)
      end
    end

    context "with goalie scorings" do
      let(:calculator) { build_calculator(goalie_scorings) }

      def build_goalie_stat(saves: 0, win: false, shutout: false)
        game = instance_double(League::Game, start_time: 1.day.ago)
        build(:pwhl_goalie_stat, league: league, league_game: nil, saves: saves, win: win, shutout: shutout).tap do |stat|
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

  describe "#calculate_by_field" do
    let(:calculator) { build_calculator(skater_scorings) }

    it "returns empty hash for empty records" do
      expect(calculator.calculate_by_field([], :skater)).to eq({})
    end

    it "returns empty hash when no scoring rules exist for position" do
      expect(calculator.calculate_by_field([{ shots: 5 }], :goalie)).to eq({})
    end

    it "returns a hash keyed by field name" do
      result = calculator.calculate_by_field([{ goals: 1, assists: 1 }], :skater)
      expect(result.keys).to match_array(["goals", "assists"])
    end

    it "calculates scores per field" do
      result = calculator.calculate_by_field([{ goals: 1, assists: 2 }], :skater)
      expect(result["goals"]).to eq(2.0)
      expect(result["assists"]).to eq(2.0)
    end

    it "sums across multiple records per field" do
      result = calculator.calculate_by_field([{ goals: 1 }, { goals: 2 }], :skater)
      expect(result["goals"]).to eq(6.0)
    end

    it "returns 0.0 for fields with no matching records" do
      result = calculator.calculate_by_field([{ goals: 1 }], :skater)
      expect(result["assists"]).to eq(0.0)
    end
  end
end
