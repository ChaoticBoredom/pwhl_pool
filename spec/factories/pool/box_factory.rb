FactoryBot.define do
  factory :pool_box, class: "Pool::Box" do
    sequence(:name) { |n| "Pool Box ##{n}" }
    association :pool
    sequence(:position) { |n| n }
  end
end
