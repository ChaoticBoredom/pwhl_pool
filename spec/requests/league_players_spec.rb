require "rails_helper"

RSpec.describe "Players", type: :request do
  include_context "pwhl teams"

  let(:pool) { create(:pool, league: pwhl, season_id: "9") }
  let(:pool_team) { create(:pool_team, pool: pool) }
  let(:skater) { create(:pwhl_skater, league: pwhl) }
  let(:team_player) { create(:pool_team_player, pool_team: pool_team, league_player: skater) }
  let(:scoring) { create(:pool_scoring, :skater, :goals, value: 3.0, pool: pool) }
  let(:user) { pool_team.owner }

  let(:mock_records) { { skater.id => [] } }

  let(:mock_raw_stats) do
    {
      stats: {
        today: { goals: 0, assists: 0 },
        yesterday: { goals: 1, assists: 0 },
        week_to_date: { goals: 0, assists: 0 },
        month_to_date: { goals: 1, assists: 0 },
        season_to_date: { goals: 2, assists: 1 },
      },
    }
  end

  let(:mock_stats) do
    mock_raw_stats.merge(
      clipped_stats: {
        today: { goals: 0, assists: 0 },
        yesterday: { goals: 1, assists: 0 },
        week_to_date: { goals: 0, assists: 0 },
        month_to_date: { goals: 1, assists: 0 },
        season_to_date: { goals: 2, assists: 1 },
      },
    )
  end

  let(:mock_raw_scores) do
    {
      scores: {
        today: 0,
        yesterday: 3.0,
        week_to_date: 0,
        month_to_date: 3.0,
        season_to_date: 6.0,
      },
    }
  end

  let(:mock_scores) do
    mock_raw_scores.merge(
      clipped_scores: {
        today: 0,
        yesterday: 3.0,
        week_to_date: 0,
        month_to_date: 3.0,
        season_to_date: 6.0,
      },
    )
  end

  before { scoring }

  describe "GET /api/players/:id?pool_id=:pool_id" do
    subject(:make_request) do
      get "/api/players/#{skater.id}",
        params: { pool_id: pool.id },
        headers: auth_headers_for(user)
    end

    before do
      allow(PlayerRecordQuery).to receive(:new).and_return(
        instance_double(PlayerRecordQuery, records: mock_records),
      )
      allow_any_instance_of(PlayerStatService).to receive(:raw_player_summaries)
        .and_return({ skater.id => mock_raw_stats })
      allow_any_instance_of(PlayerScoringService).to receive(:raw_player_summaries)
        .and_return({ skater.id => mock_raw_scores })
    end

    it "returns 200" do
      make_request
      expect(response).to have_http_status(:ok)
    end

    it "returns the player id" do
      make_request
      expect(JSON.parse(response.body)["id"]).to eq(skater.id)
    end

    it "returns raw_stats without clipped scores" do
      make_request
      raw = JSON.parse(response.body)["raw_stats"]
      expect(raw.keys).to match_array(["scores"])
      expect(raw["scores"].keys).to match_array(%w[
        today yesterday week_to_date month_to_date season_to_date
      ])
    end

    it "returns pool_scores without clipped scores" do
      make_request
      pool_scores = JSON.parse(response.body)["pool_scores"]
      expect(pool_scores.keys).to match_array(["scores"])
    end

    it "returns expanded_pool_scores without clipped scores" do
      make_request
      expanded = JSON.parse(response.body)["expanded_pool_scores"]
      expect(expanded.keys).to match_array(["scores"])
    end

    it "returns expanded_pool_scores with per-field point values" do
      make_request
      expanded = JSON.parse(response.body)["expanded_pool_scores"]["scores"]
      expect(expanded["season_to_date"].keys).to include("goals", "assists")
    end

    it "applies scoring rules to expanded_pool_scores" do
      make_request
      expanded = JSON.parse(response.body)["expanded_pool_scores"]["scores"]
      expect(expanded["season_to_date"]["goals"]).to eq(6.0)
    end

    it "returns labels" do
      make_request
      expect(JSON.parse(response.body)["labels"]).to include("goals" => "Goals")
    end
  end

  describe "GET /api/players/:id/team_player" do
    subject(:make_request) do
      get "/api/players/#{team_player.id}/team_player",
        headers: auth_headers_for(user)
    end

    before do
      allow(PlayerRecordQuery).to receive(:new).and_return(
        instance_double(PlayerRecordQuery, records: mock_records),
      )
      allow_any_instance_of(PlayerStatService).to receive(:player_summaries)
        .and_return({ team_player.id => mock_stats })
      allow_any_instance_of(PlayerScoringService).to receive(:player_summaries)
        .and_return({ team_player.id => mock_scores })
    end

    it "returns 200" do
      make_request
      expect(response).to have_http_status(:ok)
    end

    it "returns the player id" do
      make_request
      expect(JSON.parse(response.body)["id"]).to eq(skater.id)
    end

    it "returns raw_stats with clipped and unclipped scores" do
      make_request
      raw = JSON.parse(response.body)["raw_stats"]
      expect(raw.keys).to match_array(["scores", "clipped_scores"])
      expect(raw["scores"].keys).to match_array(%w[
        today yesterday week_to_date month_to_date season_to_date
      ])
    end

    it "returns pool_scores with windowed totals" do
      make_request
      scores = JSON.parse(response.body)["pool_scores"]["scores"]
      expect(scores["season_to_date"]).to eq(6.0)
    end

    it "returns expanded_pool_scores with per-field point values" do
      make_request
      expanded = JSON.parse(response.body)["expanded_pool_scores"]["scores"]
      expect(expanded["season_to_date"].keys).to include("goals", "assists")
    end

    it "applies scoring rules to expanded_pool_scores" do
      make_request
      expanded = JSON.parse(response.body)["expanded_pool_scores"]["scores"]
      expect(expanded["season_to_date"]["goals"]).to eq(6.0)
    end

    it "returns labels" do
      make_request
      expect(JSON.parse(response.body)["labels"]).to include("goals" => "Goals")
    end
  end
end
