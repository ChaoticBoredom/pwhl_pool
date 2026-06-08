require "rails_helper"

RSpec.describe "pools#show", type: :request do
  include_context "pwhl pool"

  it "returns the expected response" do
    get "/api/pools/#{pool.id}", headers: auth_headers
    body = JSON.parse(response.body)

    aggregate_failures do
      expect(response.status).to eq(200)
      expect(body["name"]).to eq("PWHL Test Pool")
      expect(body["id"]).to eq(pool.id)
      expect(body["pool_type"]).to eq("box_select")
      expect(body["trade_state"]).to eq("blocked")
      expect(body["games_active"]).to eq(false)
      expect(body["league"]).to eq({
        "id" => pwhl.id,
        "name" => "Professional Women's Hockey League",
        "short_name" => "PWHL",
      })
      expect(body["admin"]).to eq({
        "id" => admin.id,
        "name" => admin.name,
      })
      expect(body["pool_teams"]).to match_array([
        {
          "id" => pool_team.id,
          "team_name" => "Test Team",
          "rank" => 1,
          "total_score" => be_within(0.01).of(6.5),
          "user" => { "id" => owner.id, "name" => owner.name },
        },
        {
          "id" => admin_pool_team.id,
          "team_name" => "Admin Team",
          "rank" => 2,
          "total_score" => 0,
          "user" => { "id" => admin.id, "name" => admin.name },
        },
      ])
    end
  end
end
