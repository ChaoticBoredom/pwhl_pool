require "rails_helper"

RSpec.describe PlayerPositionTypes do
  describe ".position_type_for" do
    let(:league) { create(:league, :pwhl) }

    [
      ["F", :forward],
      ["LW", :forward],
      ["RW", :forward],
      ["C", :forward],
      ["D", :defense],
      ["LD", :defense],
      ["RD", :defense],
      ["G", :goalie],
    ].each do |position, expected|
      it "returns #{expected.inspect} for position #{position}" do
        player = create(:pwhl_skater, league: league, position: position)
        expect(Pool::TeamPlayer.position_type_for(player)).to eq(expected)
      end
    end

    it "raises when the position has no matching group" do
      player = create(:pwhl_skater, league: league, position: "UNKNOWN")
      expect { Pool::TeamPlayer.position_type_for(player) }.to raise_error(KeyError)
    end
  end
end
