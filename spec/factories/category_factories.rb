::FactoryBot.define do
  factory :category do
    name { "T-Shirts-#{SecureRandom.uuid}" }
  end
end
