require "rails_helper"

RSpec.describe "scorings", type: :request do
  include_context "pwhl pool"

  describe "scorings#index" do
    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["skaters"].map { |s| s["field_name"] }).to match_array(%w[
          goals assists shots hits
        ])

        expect(body["goalies"].map { |s| s["field_name"] }).to match_array(%w[
          win saves
        ])

        [
          ["skaters", "goals", 2.0],
          ["skaters", "assists", 1.0],
          ["skaters", "shots", 0.5],
          ["skaters", "hits", 0.5],
          ["goalies", "win", 2.0],
          ["goalies", "saves", 0.1],
        ].each do |roster_type, field, value|
          entry = body[roster_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(value),
            "#{roster_type} #{field} value mismatch"
        end
      end
    end
  end
end
