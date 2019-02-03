# frozen_string_literal: true

FactoryBot.define do
  sequence(:uid) { |_| Random.srand }
  sequence(:address) { |_| Eth::Key.new.address.downcase }
  sequence(:username) { |n| "real_user_#{n}" }
  sequence(:email) { |n| "user-#{Random.rand(10_000) + n}@test.com" }

  factory :user, class: 'User' do
    uid { generate(:uid) }
    address { generate(:address) }
    after(:build) do |user|
      user.address = user.address.downcase
    end

    factory :user_with_email do
      email { generate(:email) }
    end

    factory :kyc_officer_user do
      after(:create) do |admin, _evaluator|
        admin.groups << Group.find_by(name: Group.groups[:kyc_officer])
      end
    end
  end
end
