require "rails_helper"

RSpec.describe "Commissioner::Trade::Windows", type: :request do
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:auth_headers) { auth_headers_for(admin) }
  let(:league) { create(:league, :pwhl) }
  let(:pool) { create(:pool, admin: admin, league: league, trade_policy: :windowed) }

  let(:base_url) { "/api/commissioner/#{pool.id}/trade_windows" }

  let(:window_start) { "2026-07-01T00:00:00Z" }
  let(:window_end) { "2026-07-08T00:00:00Z" }
  let(:valid_params) { { open_window_start: window_start, open_window_end: window_end } }

  describe "GET /commissioner/:pool_id/trade_windows" do
    let!(:future_window) { create(:trade_window, :future, pool: pool) }
    let!(:past_window) { create(:trade_window, :past, pool: pool) }

    subject(:get_index) { get base_url, headers: auth_headers }

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        get_index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the pool's trade policy is not windowed or windowed_overflow" do
      let(:pool) { create(:pool, admin: admin, league: league, trade_policy: :open) }

      it "returns 403" do
        get_index
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 200" do
      get_index
      expect(response).to have_http_status(:ok)
    end

    it "returns the pool's trade windows ordered chronologically" do
      get_index
      ids = response.parsed_body.map { |w| w["id"] }
      expect(ids).to eq([past_window.id, future_window.id])
    end

    it "excludes trade windows belonging to other pools" do
      other_pool = create(:pool, league: league, trade_policy: :windowed)
      create(:trade_window, pool: other_pool)

      get_index
      ids = response.parsed_body.map { |w| w["id"] }
      expect(ids).to match_array([past_window.id, future_window.id])
    end
  end

  describe "POST /commissioner/:pool_id/trade_windows" do
    subject(:post_create) { post base_url, params: valid_params.to_json, headers: auth_headers }

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        post_create
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the range is invalid" do
      let(:window_start) { "2026-07-08T00:00:00Z" }
      let(:window_end) { "2026-07-01T00:00:00Z" }

      it "returns 422" do
        post_create
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "surfaces the validation error" do
        post_create
        expect(response.parsed_body["errors"]).to include("Open window start must be before end")
      end
    end

    it "returns 201" do
      post_create
      expect(response).to have_http_status(:created)
    end

    it "creates a trade window for the pool" do
      expect { post_create }.to change { pool.trade_windows.count }.by(1)
    end

    it "returns the created window's start and end" do
      post_create
      expect(response.parsed_body).to match(
        a_hash_including(
          "window_start" => "2026-07-01T00:00:00.000Z",
          "window_end" => "2026-07-08T00:00:00.000Z",
        )
      )
    end

    context "when open_window_start is missing" do
      let(:valid_params) { { open_window_end: window_end } }

      it "returns 422" do
        post_create
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when a date is unparseable" do
      let(:window_start) { "not-a-date" }

      it "returns 422" do
        post_create
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "surfaces the invalid field in the error" do
        post_create
        expect(response.parsed_body["error"]).to eq("open_window_start is not a valid time")
      end
    end
  end

  describe "PATCH /commissioner/:pool_id/trade_windows/:id" do
    let!(:trade_window) { create(:trade_window, pool: pool) }

    subject(:patch_update) do
      patch "#{base_url}/#{trade_window.id}", params: valid_params.to_json, headers: auth_headers
    end

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        patch_update
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the window does not exist" do
      it "returns 404" do
        patch "#{base_url}/#{SecureRandom.uuid}", params: valid_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the window belongs to a different pool" do
      let(:other_pool) { create(:pool, league: league, trade_policy: :windowed) }
      let(:other_window) { create(:trade_window, pool: other_pool) }

      it "returns 404" do
        patch "#{base_url}/#{other_window.id}", params: valid_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    it "returns 200" do
      patch_update
      expect(response).to have_http_status(:ok)
    end

    it "updates the window's range" do
      patch_update
      expect(trade_window.reload.open_window.begin.iso8601(3)).to eq("2026-07-01T00:00:00.000Z")
    end

    context "when a date is unparseable" do
      let(:window_start) { "not-a-date" }

      it "returns 422" do
        patch_update
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /commissioner/:pool_id/trade_windows/:id" do
    let!(:trade_window) { create(:trade_window, pool: pool) }

    subject(:delete_destroy) { delete "#{base_url}/#{trade_window.id}", headers: auth_headers }

    context "when not the pool commissioner" do
      let(:auth_headers) { auth_headers_for(other_user) }

      it "returns 403" do
        delete_destroy
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the window does not exist" do
      it "returns 404" do
        delete "#{base_url}/#{SecureRandom.uuid}", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    it "returns 204" do
      delete_destroy
      expect(response).to have_http_status(:no_content)
    end

    it "deletes the window" do
      expect { delete_destroy }.to change { Trade::Window.count }.by(-1)
    end
  end
end
