require "rails_helper"

RSpec.describe "scorings", type: :request do
  include_context "pwhl pool"

  describe "scorings#index" do
    # The shared context only has 6 scorings set up, so the index action
    # should return ONLY those 6 scorings
    it "returns the expected response" do
      get "/api/pools/#{pool.id}/pool_scoring", headers: auth_headers
      body = JSON.parse(response.body)

      aggregate_failures do
        expect(response.status).to eq(200)

        expect(body["skater"].map { |s| s["field_name"] }).to match_array(%w[goals assists shots hits])

        expect(body["goalie"].map { |s| s["field_name"] }).to match_array(%w[win saves])

        [
          ["skater", "goals", 2.0],
          ["skater", "assists", 1.0],
          ["skater", "shots", 0.5],
          ["skater", "hits", 0.5],
          ["goalie", "win", 2.0],
          ["goalie", "saves", 0.1],
        ].each do |roster_type, field, value|
          entry = body[roster_type].find { |s| s["field_name"] == field }
          expect(entry["value"]).to eq(value),
            "#{roster_type} #{field} value mismatch: expected #{value.inspect}, got #{entry["value"].inspect}"
        end
      end
    end
  end
end
