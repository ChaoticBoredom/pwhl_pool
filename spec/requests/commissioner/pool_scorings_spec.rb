require "rails_helper"

RSpec.describe "Commissioner::PoolScoring", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pwhl) { create(:league, :pwhl) }
  let(:pool) { create(:pool, admin: admin, league: pwhl) }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }

  let(:full_scoring_params) do
    {
      scoring: [
        { field_name: "goals", stat_type: "skater", value: 2.0 },
        { field_name: "assists", stat_type: "skater", value: 1.0 },
        { field_name: "penalty_minutes", stat_type: "skater", value: 0.25 },
        { field_name: "shots", stat_type: "skater", value: 0.25 },
        { field_name: "hits", stat_type: "skater", value: 0.25 },
        { field_name: "plus_minus", stat_type: "skater", value: 0.0 },
        { field_name: "power_play_goals", stat_type: "skater", value: 1.0 },
        { field_name: "short_handed_goals", stat_type: "skater", value: 2.0 },
        { field_name: "shots_blocked", stat_type: "skater", value: 0.0 },
        { field_name: "faceoffs_taken", stat_type: "skater", value: 0.0 },
        { field_name: "faceoffs_won", stat_type: "skater", value: 0.0 },
        { field_name: "game_winning_goals", stat_type: "skater", value: 0.0 },
        { field_name: "goals", stat_type: "goalie", value: 5.0 },
        { field_name: "assists", stat_type: "goalie", value: 2.0 },
        { field_name: "goals_against", stat_type: "goalie", value: 0.0 },
        { field_name: "shots_against", stat_type: "goalie", value: 0.0 },
        { field_name: "penalty_minutes", stat_type: "goalie", value: 0.25 },
        { field_name: "win", stat_type: "goalie", value: 2.0 },
        { field_name: "shutout", stat_type: "goalie", value: 2.0 },
        { field_name: "saves", stat_type: "goalie", value: 0.05 },
        { field_name: "game_started", stat_type: "goalie", value: 0.0 },
      ],
    }
  end

  shared_examples "a scoring payload with incorrect fields" do
    let(:scoring_rows) { pool.scoring.order(:id) }

    context "with a missing scoreable field" do
      let(:incomplete_params) { { scoring: full_scoring_params[:scoring].reject { |entry| entry[:field_name] == "hits" } } }

      it "returns 'unprocessable_content'" do
        submit(incomplete_params)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not change any scoring rows" do
        expect { submit(incomplete_params) }.to_not change { scoring_rows.reload.pluck(:id, :value) }
      end

      it "returns an error showing the missing field" do
        submit(incomplete_params)

        expect(response.parsed_body).to eq(
          "error" => "Missing scoreable fields",
          "fields" => [["skater", "hits"]]
        )
      end
    end

    context "with an extra field not present in SCOREABLE_STATS" do
      let(:junk_params) do
        {
          scoring: full_scoring_params[:scoring] + [
            { field_name: "garbage_field", stat_type: "skater", value: 1.0 },
          ],
        }
      end

      it "returns 'unprocessable_content'" do
        submit(junk_params)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not change any scoring rows" do
        expect { submit(junk_params) }.to_not change { scoring_rows.reload.pluck(:id, :value) }
      end

      it "returns an error showing the extra field" do
        submit(junk_params)

        expect(response.parsed_body).to eq(
          "error" => "Unexpected scoring fields",
          "fields" => [["skater", "garbage_field"]]
        )
      end
    end
  end

  describe "POST /api/commissioner/:pool_id/pool_scoring" do
    def submit(params = full_scoring_params, headers: admin_headers)
      post "/api/commissioner/#{pool.id}/pool_scoring", params: params.to_json, headers: headers
    end

    it_behaves_like "a commissioner-only request"
    it_behaves_like "a scoring payload with incorrect fields"
    it_behaves_like "a blocked request on a completed pool"

    it "creates a row for every submitted field" do
      expect { submit }.to change { pool.scoring.count }.by(21)
    end

    it "persists a zero value rather than dropping it" do
      submit

      expect(pool.scoring.find_by(field_name: "plus_minus", stat_type: "skater").value).to eq(0.0)
    end

    it "returns the created rows grouped by stat type" do
      submit

      skater_goals = response.parsed_body["skater"].find { |f| f["field_name"] == "goals" }

      expect(skater_goals["value"]).to eq(2.0)
    end

    it "returns a 201" do
      submit

      expect(response).to have_http_status(:created)
    end

    it "rejects a second create call once scoring already exists for the pool" do
      submit
      submit

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT /api/commissioner/:pool_id/pool_scoring" do
    let!(:goals) { create(:pool_scoring, :skater, :goals, value: 5.0, pool: pool) }
    let!(:assists) { create(:pool_scoring, :skater, :assists, value: 3.0, pool: pool) }
    let!(:shots_blocked) { create(:pool_scoring, :skater, :shots_blocked, value: 0.5, pool: pool) }

    let(:full_update_params) do
      ids = {
        ["skater", "goals"] => goals.id,
        ["skater", "assists"] => assists.id,
        ["skater", "shots_blocked"] => shots_blocked.id,
      }

      {
        scoring: full_scoring_params[:scoring].map do |entry|
          entry.merge(id: ids[[entry[:stat_type], entry[:field_name]]])
        end,
      }
    end

    def submit(params = full_update_params, headers: admin_headers)
      put "/api/commissioner/#{pool.id}/pool_scoring", params: params.to_json, headers: headers
    end

    it_behaves_like "a commissioner-only request"
    it_behaves_like "a scoring payload with incorrect fields"
    it_behaves_like "a blocked request on a completed pool"

    it "updates the value for a persisted row" do
      expect { submit }.to change { goals.reload.value }.from(5.0).to(2.0)
    end

    it "persists a zero value" do
      expect { submit }.to change { shots_blocked.reload.value }.from(0.5).to(0.0)
    end

    it "creates a row for a field that doesn't exist" do
      expect { submit }.to change {
        pool.scoring.find_by(stat_type: "skater", field_name: "hits")&.value
      }.from(nil).to(0.25)
    end

    it "updates an existing row when an entry is missing an id" do
      # full_scoring_params has no ids in the payload
      expect { submit(full_scoring_params) }.to change { goals.reload.value }.from(5.0).to(2.0)
    end

    it "returns a 200" do
      submit

      expect(response).to have_http_status(:ok)
    end

    it "responds 404 when an id does not belong to the pool" do
      other_pool_scoring = create(:pool_scoring, :skater, :goals)
      foreign_id_params = {
        scoring: full_update_params[:scoring].map do |entry|
          entry[:id] == goals.id ? entry.merge(id: other_pool_scoring.id) : entry
        end,
      }

      submit(foreign_id_params)

      expect(response).to have_http_status(:not_found)
    end

    it "applies none of the changes when one entry is invalid" do
      # goals is updated before assists
      invalid_params = {
        scoring: full_update_params[:scoring].map do |entry|
          entry[:id] == assists.id ? entry.merge(value: nil) : entry
        end,
      }

      expect { submit(invalid_params) }.to_not change { goals.reload.value }
    end
  end
end
