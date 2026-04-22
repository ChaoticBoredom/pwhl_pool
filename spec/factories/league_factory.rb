FactoryBot.define do
  factory :league do
    sequence(:name) { |n| "League \##{n}" }
    short_name { Faker::Name.initials(number: 4) }

    trait :pwhl do
      name { "Professional Women's Hockey League" }
      short_name { "PWHL" }
    end
  end
end
