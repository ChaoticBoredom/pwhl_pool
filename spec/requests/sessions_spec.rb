RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "POST /api/session (login)" do
    context "with valid credentials" do
      it "returns 200" do
        post "/api/session", params: { email_address: user.email_address, password: "password123" }
        expect(response).to have_http_status(:ok)
      end

      it "returns a token" do
        post "/api/session", params: { email_address: user.email_address, password: "password123" }
        expect(JSON.parse(response.body).dig("data", "token")).to be_present
      end

      it "returns the user id" do
        post "/api/session", params: { email_address: user.email_address, password: "password123" }
        expect(JSON.parse(response.body).dig("data", "user")).to eq(user.id)
      end

      it "creates a session" do
        expect {
          post "/api/session", params: { email_address: user.email_address, password: "password123" }
        }.to change(Session, :count).by(1)
      end
    end

    context "with invalid credentials" do
      it "returns 401" do
        post "/api/session", params: { email_address: user.email_address, password: "wrong" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create a session" do
        expect {
          post "/api/session", params: { email_address: user.email_address, password: "wrong" }
        }.to_not change(Session, :count)
      end
    end

    context "with unknown email" do
      it "returns 401" do
        post "/api/session", params: { email_address: "nobody@nowhere.com", password: "password123" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/session (logout)" do
    let!(:session) { user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1") }

    it "destroys the session" do
      expect {
        delete "/api/session", headers: { "Authorization" => "Bearer #{session.token}" }
      }.to change(Session, :count).by(-1)
    end

    it "returns 200" do
      delete "/api/session", headers: { "Authorization" => "Bearer #{session.token}" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "unauthenticated access" do
    it "returns 401 without a token" do
      get "/api/pools"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid token" do
      get "/api/pools", headers: { "Authorization" => "Bearer invalid_token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
