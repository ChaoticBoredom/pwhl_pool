RSpec.shared_examples "an authenticated request" do
  it "requires authentication" do
    submit(headers: {})

    expect(response).to have_http_status(:unauthorized)
  end
end

RSpec.shared_examples "a commissioner-only request" do
  it_behaves_like "an authenticated request"

  it "is forbidden for non-commissioners" do
    submit(headers: other_headers)

    expect(response).to have_http_status(:forbidden)
  end
end

RSpec.shared_examples "a god-only request" do
  it_behaves_like "an authenticated request"

  it "is forbidden for non-god users" do
    submit(headers: basic_headers)

    expect(response).to have_http_status(:forbidden)
  end
end
