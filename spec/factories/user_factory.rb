FactoryBot.define do
  factory :user do
    name          { Faker::Name.name }
    sequence(:email_address) { |n| "#{Faker::Internet.username}.#{n}@example.com" }
    password      { "password123" }
  end
end
