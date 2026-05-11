require "rails_helper"

RSpec.describe BoxGenerationService, type: :service do
  include_context "pwhl teams"

  let(:pool) { create(:pool, league: pwhl, season_id: "9", reference_season_id: "8") }
  let (:config) { BoxGeneration::Config.new }

  subject(:service) { described_class.new(pool, config) }

  let(:boston) { team("1") }
  let(:toronto) { team("6") }

  describe "#fetch_players" do
    let!(:player1) { create(:pwhl_skater, league: pwhl, current_team: boston) }
    let!(:player2) { create(:pwhl_skater, league: pwhl, current_team: toronto) }
    let!(:player_to_exclude) { create(:pwhl_skater, league: pwhl, current_team: boston) }

    context "with no team filter" do
      it "returns all league players" do
        expect(service.send(:fetch_players)).to include(player1, player2)
      end
    end

    context "with team filter" do
      let(:config) { BoxGeneration::Config.new(teams: ["BOS"]) }

      it "includes players from specified teams" do
        expect(service.send(:fetch_players)).to include(player1)
      end

      it "excludes players from other teams" do
        expect(service.send(:fetch_players)).to_not include(player2)
      end
    end

    context "with excluded_player_ids" do
      let(:config) { BoxGeneration::Config.new(excluded_player_ids: [player_to_exclude.id]) }

      it "excludes specified players" do
        expect(service.send(:fetch_players)).to_not include(player_to_exclude)
      end

      it "includes non-excluded players" do
        expect(service.send(:fetch_players)).to include(player1)
      end
    end
  end

  describe "#score_players" do
    let(:skater) { create(:pwhl_skater, league: pwhl) }
    let(:goalie) { create(:pwhl_goalie, league: pwhl) }
    let(:players) { [skater, goalie] }
    let(:records) { { skater.id => [:record1], goalie.id => [] } }
    let(:calculator) { instance_double(ScoringCalculator) }

    before(:each) do
      allow(PlayerRecordQuery).to receive(:new).and_return(
        instance_double(PlayerRecordQuery, records: records)
      )
      allow(ScoringCalculator).to receive(:new).and_return(calculator)
      allow(calculator).to receive(:calculate).with([:record1], "skater").and_return(10.0)
      allow(calculator).to receive(:calculate).with([], "goalie").and_return(0.0)
    end

    it "returns a hash of player id to score" do
      result = service.send(:score_players, players)
      expect(result).to eq({ skater.id => 10.0, goalie.id => 0.0 })
    end
  end

  describe "#sort_and_group" do
    let(:skater1) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "F") }
    let(:skater2) { create(:pwhl_skater, league: pwhl, current_team: toronto, position: "F") }
    let(:skater3) { create(:pwhl_skater, league: pwhl, current_team: boston, position: "RW") }
    let(:rookie) { create(:pwhl_skater, :rookie, league: pwhl, current_team: boston, position: "F") }

    context "grouping by team" do
      let(:scores) { { skater1.id => 10.0, skater2.id => 5.0 } }

      it "groups players by team" do
        result = service.send(:sort_and_group, scores)
        expect(result.keys).to include(boston.id, toronto.id)
      end
    end

    context "sorting within team" do
      let(:scores) { { skater1.id => 10.0, skater3.id => 15.0 } }

      it "sorts by score descending" do
        result = service.send(:sort_and_group, scores)
        expect(result[boston.id][["F", false]].first[:id]).to eq(skater3.id)
      end
    end

    context "position normalization" do
      let(:scores) { { skater3.id => 5.0 } }

      it "normalizes RW to F" do
        result = service.send(:sort_and_group, scores)
        expect(result[boston.id].keys).to include(["F", false])
      end

      it "does not create a RW key" do
        result = service.send(:sort_and_group, scores)
        expect(result[boston.id].keys).to_not include(["RW", false])
      end
    end

    context "rookie grouping" do
      let(:scores) { { skater1.id => 10.0, rookie.id => 8.0 } }

      it "separates rookies into their own group" do
        result = service.send(:sort_and_group, scores)
        expect(result[boston.id].keys).to include(["F", false], ["F", true])
      end

      it "still sorts rookies correctly" do
        result = service.send(:sort_and_group, scores)
        expect(result[boston.id][["F", true]].first[:id]).to eq(rookie.id)
      end
    end
  end

  describe "#generate_boxes" do
    let(:player1) { { id: "1", name: "Alice", position: "F", rookie: false, score: 10.0, team_id: team("1").id } }
    let(:player2) { { id: "2", name: "Bob", position: "F", rookie: false, score: 8.0, team_id: team("6").id } }

    let(:sorted) do
      {
        team("1").id => { ["F", false] => [player1] },
        team("6").id => { ["F", false] => [player2] },
      }
    end

    let(:boxes) { [BoxGeneration::BoxDefinition.new(name: "Forwards Box 1", position: "F", rank_range: 0..0)] }
    let(:config) { BoxGeneration::Config.new(boxes: boxes) }

    it "keys result by box name" do
      expect(service.send(:generate_boxes, sorted).keys).to eq(["Forwards Box 1"])
    end

    it "includes correct ids" do
      expect(service.send(:generate_boxes, sorted)["Forwards Box 1"][:ids]).to match_array(["1", "2"])
    end

    it "includes correct names" do
      expect(service.send(:generate_boxes, sorted)["Forwards Box 1"][:names]).to match_array(["Alice", "Bob"])
    end
  end

  describe "#players_for_box" do
    let(:player1) { { id: "1", name: "Alice", position: "F", score: 15.0, team_id: boston.id } }
    let(:player2) { { id: "2", name: "Bob", position: "F", score: 10.0, team_id: boston.id } }
    let(:player3) { { id: "3", name: "Carol", position: "F", score: 5.0, team_id: boston.id } }
    let(:player4) { { id: "4", name: "Dana", position: "F", score: 12.0, team_id: toronto.id } }

    context "per-team mode (max_players_per_team set)" do
      let(:config) { BoxGeneration::Config.new(max_players_per_team: 1) }

      let(:sorted) do
        { boston.id => { ["F", false] => [player1, player2, player3] } }
      end

      [
        ["box 1 — rank 0", 0..0, ["1"]],
        ["box 2 — rank 1", 1..1, ["2"]],
        ["box 3 — rank 2", 2..2, ["3"]],
      ].each do |desc, rank_range, expected_ids|
        context desc do
          let(:box_def) { BoxGeneration::BoxDefinition.new(name: "Box", position: "F", rank_range: rank_range) }

          it "returns players at #{rank_range}" do
            result = service.send(:players_for_box, sorted, box_def)
            expect(result.map { |p| p[:id] }).to eq(expected_ids)
          end
        end
      end

      context "when rank_range would exceed max_players_per_team" do
        let(:box_def) { BoxGeneration::BoxDefinition.new(name: "Box", position: "F", rank_range: 0..1) }

        it "cap takes precedence over rank_range" do
          result = service.send(:players_for_box, sorted, box_def)
          expect(result.map { |p| p[:id] }).to eq(["1"])
        end
      end
    end
  end

  describe "#candidates_for" do
    let(:forward) { { id: "1", position: "F", rookie: false, score: 10.0, name: "A", team_id: boston.id } }
    let(:rookie_forward) { { id: "2", position: "F", rookie: true, score: 8.0, name: "B", team_id: boston.id } }

    let(:team_groups) do
      {
        ["F", false] => [forward],
        ["F", true] => [rookie_forward],
      }
    end

    context "when rookie is false" do
      let(:box_def) { BoxGeneration::BoxDefinition.new(name: "Box", position: "F", rookie: false) }

      it "returns only non-rookie forwards" do
        expect(service.send(:candidates_for, team_groups, box_def)).to eq([forward])
      end
    end

    context "when rookie is true" do
      let(:box_def) { BoxGeneration::BoxDefinition.new(name: "Box", position: "F", rookie: true) }

      it "returns only rookie forwards" do
        expect(service.send(:candidates_for, team_groups, box_def)).to eq([rookie_forward])
      end
    end

    context "when rookie is nil" do
      let(:box_def) { BoxGeneration::BoxDefinition.new(name: "Box", position: "F", rookie: nil) }

      it "combines rookie and non-rookie players" do
        expect(service.send(:candidates_for, team_groups, box_def)).to include(forward, rookie_forward)
      end
    end
  end
end
