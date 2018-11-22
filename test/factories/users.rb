# frozen_string_literal: true

FactoryBot.define do
  sequence(:uid) { |_| Random.srand }
  sequence(:address) { |_| format('0xa%039d', Random.srand) }

  factory :user, class: 'User' do
    uid { generate(:uid) }
    address { generate(:address) }
  end
end
