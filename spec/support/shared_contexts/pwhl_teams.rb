# api_id "7" is used by the PWHL API to represent TBD opponents in
# unresolved playoff matchups. It is intentionally excluded here as the
# service does not currently handle null team associations. If automated
# game loading is added, this will need to be addressed before processing
# scheduled playoff games with unresolved opponents.

RSpec.shared_context "pwhl teams" do
  let!(:pwhl) { create(:league, :pwhl) }

  let!(:teams) do
    [
      { api_id: "1", name: "Boston Fleet", short_code: "BOS" },
      { api_id: "2", name: "Minnesota Frost", short_code: "MIN" },
      { api_id: "3", name: "Montréal Victoire", short_code: "MTL" },
      { api_id: "4", name: "New York Sirens", short_code: "NY"  },
      { api_id: "5", name: "Ottawa Charge", short_code: "OTT" },
      { api_id: "6", name: "Toronto Sceptres", short_code: "TOR" },
      { api_id: "8", name: "Seattle Torrent", short_code: "SEA" },
      { api_id: "9", name: "Vancouver Goldeneyes", short_code: "VAN" },
    ].map { |attrs| create(:league_team, attrs.merge(league: pwhl)) }
  end

  def team(api_id)
    teams.find { |t| t.api_id == api_id.to_s }
  end
end
