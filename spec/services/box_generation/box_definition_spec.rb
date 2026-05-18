require "rails_helper"

RSpec.describe BoxGeneration::BoxDefinition do
  describe "#rank_range" do
    [
      [1, 1, 0..0],
      [1, 2, 0..1],
      [2, 1, 1..1],
      [2, 2, 1..2],
      [3, 2, 2..3],
      [4, 5, 3..7],
    ].each do |rank, count, expected|
      it "returns #{expected} for rank: #{rank}, count: #{count}" do
        box = described_class.new(name: "Test Box", position: "F", rank: rank, count: count)
        expect(box.rank_range).to eq(expected)
      end
    end
  end

  describe "defaults" do
    subject(:box) { described_class.new(name: "Test Box", position: "F") }

    [
      [:rookie, false],
      [:rank, 1],
      [:count, 1],
    ].each do |attribute, default_value|
      it "defaults #{attribute} to #{default_value}" do
        expect(box.send(attribute)).to eq(default_value)
      end
    end
  end

  describe "rookie: nil" do
    it "accepts nil for rookie" do
      box = described_class.new(name: "Goalies Box", position: "G", rookie: nil)
      expect(box.rookie).to be_nil
    end
  end
end
