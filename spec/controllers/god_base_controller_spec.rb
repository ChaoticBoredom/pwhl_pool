require "rails_helper"

RSpec.describe God::BaseController, type: :controller do
  controller(God::BaseController) do
    def index
      render json: { ok: true }
    end
  end

  let(:god_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user) }

  context "when the user is a god" do
    before { request.headers.merge!(auth_headers_for(god_user)) }

    it "allowed the request through" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is not a god" do
    before { request.headers.merge!(auth_headers_for(regular_user)) }

    it "returns 403" do
      get :index
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when unauthenticated" do
    it "returns 401" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
