require "rails_helper"

RSpec.describe Commissioner::BaseController, type: :controller do
  controller(Commissioner::BaseController) do
    def index
      render json: { ok: true }
    end
  end

  let(:league) { create(:league, :pwhl) }
  let(:commissioner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pool) { create(:pool, admin: commissioner, league: league) }

  context "when the user is the pool commissioner" do
    before { request.headers.merge!(auth_headers_for(commissioner)) }

    it "allows the request through" do
      get :index, params: { pool_id: pool.id }
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is not the pool commissioner" do
    before { request.headers.merge!(auth_headers_for(other_user)) }

    it "returns 403" do
      get :index, params: { pool_id: pool.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the user is a god user" do
    let(:god_user) { create(:user, admin: true) }
    before { request.headers.merge!(auth_headers_for(god_user)) }

    it "allows the request through" do
      get :index, params: { pool_id: pool.id }
      expect(response).to have_http_status(:ok)
    end
  end

  context "when pool_id is missing" do
    before { request.headers.merge!(auth_headers_for(commissioner)) }

    it "returns 404" do
      get :index, params: { pool_id: "bad id" }
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when unauthenticated" do
    it "returns 401" do
      get :index, params: { pool_id: pool.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
