FactoryBot.define do
  factory :league do
    trait :pwhl do
      name { "Professional Women's Hockey League" }
      short_name { "PWHL" }
    end
  end
end
