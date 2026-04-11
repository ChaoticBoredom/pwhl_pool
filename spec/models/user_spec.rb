require "rails_helper"

RSpec.describe User, type: :model do
  it { should validate_presence_of(:email_address) }
  it { should normalize(:email_address).from("  soMEthing@BAD.com\n").to("something@bad.com") }
end
