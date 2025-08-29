FactoryBot.define do
  factory :review do
    sequence(:booking_code) { |n| "BKA#{n}" }
    rating { 5 }
    comment { "Good" }
    status { "pending" }
    association :user
    association :request
  end
end
