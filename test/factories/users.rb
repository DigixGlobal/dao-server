# frozen_string_literal: true

FactoryBot.define do
  sequence(:uid) { |_| Random.srand }
  sequence(:address) { |_| Eth::Key.new.address.downcase }
  sequence(:username) { |n| "real_user_#{n}" }
  sequence(:email) { |n| "user-#{n}@test.com" }

  factory :user, class: 'User' do
    uid { generate(:uid) }
    address { generate(:address) }
    after(:build) do |user|
      user.address = user.address.downcase
    end

    factory :user_with_email do
      email { generate(:email) }
    end
  end
end
