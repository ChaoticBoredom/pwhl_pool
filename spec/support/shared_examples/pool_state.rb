RSpec.shared_examples "a blocked request on a completed pool" do
  before(:each) { pool.update!(state: :completed) }

  it "return forbidden" do
    submit

    expect(response).to have_http_status(:forbidden)
  end

  it "returns a message about the pool being completed" do
    submit

    expect(response.parsed_body).to eq("error" => "Pool is completed")
  end
end
