# frozen_string_literal: true

FactoryBot.define do
  sequence(:uid) { |_| Random.srand }
  sequence(:address) { |_| Eth::Key.new.address.downcase }
  sequence(:username) { |_| "real_user_#{Random.rand(1_000..9_999)}" }
  sequence(:email) { |_| "user-#{Random.srand}@test.com" }

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
