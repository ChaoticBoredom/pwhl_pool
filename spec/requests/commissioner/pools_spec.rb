require "rails_helper"

RSpec.describe "Commissioner::Pools", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pool) { create(:pool, admin: admin, state: :draft) }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:other_headers) { auth_headers_for(other_user) }
  let(:json) { JSON.parse(response.body) }

  describe "PATCH /api/commissioner/:pool_id" do
    let(:valid_params) do
      { pool: { name: "Updated Name", trade_policy: "open" } }
    end
    let(:payload) { valid_params.to_json }

    it "updates the pool" do
      patch "/api/commissioner/#{pool.id}", params: payload, headers: admin_headers

      expect(pool.reload.name).to eq("Updated Name")
      expect(pool.reload.trade_policy).to eq("open")
    end

    it "returns ok" do
      patch "/api/commissioner/#{pool.id}", params: payload, headers: admin_headers

      expect(response).to have_http_status(:ok)
    end

    it "rejects invalid params" do
      patch "/api/commissioner/#{pool.id}",
        params: { pool: { name: nil } }.to_json,
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns errors on invalid params" do
      patch "/api/commissioner/#{pool.id}",
        params: { pool: { name: nil } }.to_json,
        headers: admin_headers

      expect(json["errors"]).to be_present
    end

    it "does not allow changing season_id" do
      patch "/api/commissioner/#{pool.id}",
        params: { pool: { season_id: "999" } }.to_json,
        headers: admin_headers

      expect(pool.reload.season_id).to_not eq("999")
    end

    it "is forbidden for non-admins" do
      patch "/api/commissioner/#{pool.id}", params: payload, headers: other_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      patch "/api/commissioner/#{pool.id}", params: payload

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/commissioner/:pool_id/activate" do
    context "when pool has active boxes" do
      before { create(:pool_box, pool: pool, active: true) }

      it "activates the pool" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(pool.reload).to be_pool_state_active
      end

      it "returns ok" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(response).to have_http_status(:ok)
      end

      it "returns the new state" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(json["state"]).to eq("active")
      end
    end

    context "when no active boxes exist" do
      it "returns 422" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns an error mentioning boxes" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(json["error"]).to match(/box/i)
      end
    end

    context "when pool is not in draft state" do
      before do
        pool.pool_state_active!
        create(:pool_box, pool: pool, active: true)
      end

      it "returns 422" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns an error mentioning draft" do
        patch "/api/commissioner/#{pool.id}/activate", headers: admin_headers

        expect(json["error"]).to match(/draft/i)
      end
    end

    context "when the user is not the pool admin" do
      it "returns 403" do
        patch "/api/commissioner/#{pool.id}/activate", headers: other_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "requires authentication" do
      patch "/api/commissioner/#{pool.id}/activate"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
