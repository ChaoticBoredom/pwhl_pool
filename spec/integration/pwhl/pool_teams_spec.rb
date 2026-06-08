require "rails_helper"

RSpec.describe "pool_teams#show", type: :request do
  include_context "pwhl pool"

  it "returns the expected response" do
    get "/api/pool_teams/#{pool_team.id}", headers: auth_headers
    body = JSON.parse(response.body)

    aggregate_failures do
      expect(response.status).to eq(200)
      expect(body["id"]).to eq(pool_team.id)
      expect(body["team_name"]).to eq("Test Team")
      expect(body["pool_id"]).to eq(pool.id)
      expect(body["total_score"]).to be_within(0.01).of(6.5)
      expect(body["trade_state"]).to eq("blocked")
      expect(body["games_active"]).to eq(false)
      expect(body["owner"]).to eq({ "id" => owner.id, "name" => owner.name })
      expect(body["previous_team"]).to eq([])

      skater_entry = body["current_team"].find { |p| p["league_player_id"] == skater.id }
      goalie_entry = body["current_team"].find { |p| p["league_player_id"] == goalie.id }

      skater_scores = {
        "today" => be_within(0.01).of(4.5),
        "yesterday" => 0,
        "week_to_date" => be_within(0.01).of(4.5),
        "month_to_date" => be_within(0.01).of(4.5),
        "season_to_date" => be_within(0.01).of(4.5),
      }

      goalie_scores = {
        "today" => be_within(0.01).of(2.0),
        "yesterday" => 0,
        "week_to_date" => be_within(0.01).of(2.0),
        "month_to_date" => be_within(0.01).of(2.0),
        "season_to_date" => be_within(0.01).of(2.0),
      }

      [
        [skater_entry, team_player, skater, skater_box, 4.5, skater_scores],
        [goalie_entry, goalie_team_player, goalie, goalie_box, 2.0, goalie_scores],
      ].each do |entry, tp, player, box, pool_score, scores|
        expect(entry["id"]).to eq(tp.id), "#{player.name} team_player id mismatch"
        expect(entry["league_player_id"]).to eq(player.id), "#{player.name} league_player_id mismatch"
        expect(entry["name"]).to eq(player.name), "#{player.name} name mismatch"
        expect(entry["current_team_short_code"]).to eq("BOS"), "#{player.name} team mismatch"
        expect(entry["added_at"]).to eq(tp.added_at.iso8601(3)), "#{player.name} added_at mismatch"
        expect(entry["pool_box_position"]).to eq(box.position), "#{player.name} box position mismatch"
        expect(entry["scores"]["pool_score"]).to be_within(0.01).of(pool_score), "#{player.name} pool_score mismatch"
        expect(entry["scores"]["scores"]).to match(scores), "#{player.name} scores mismatch"
        expect(entry["scores"]["clipped_scores"]).to match(scores), "#{player.name} clipped_scores mismatch"
        expect(entry["games"]).to eq({
          "upcoming" => {},
          "today" => { "id" => game.id },
        }), "#{player.name} games mismatch"
      end
    end
  end
end
