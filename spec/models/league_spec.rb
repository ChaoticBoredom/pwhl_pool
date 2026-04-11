require "rails_helper"

RSpec.describe League, type: :model do
  it { should validate_presence_of(:name) }
end
