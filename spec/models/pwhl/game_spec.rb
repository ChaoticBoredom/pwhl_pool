require "rails_helper"

RSpec.describe Pwhl::Game, type: :model do
  it { should have_many(:skater_records).dependent(:destroy) }
  it { should have_many(:goalie_records).dependent(:destroy) }
end
