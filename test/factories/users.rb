# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  sequence(:uid) { |_| SecureRandom.uuid }
  sequence(:address) { |_| Eth::Key.new.address.downcase }
  sequence(:username) { |_| Faker::Internet.username.tr('.', '_') }
  sequence(:email) { |_| Faker::Internet.safe_email }

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
