# frozen_string_literal: true

FactoryBot.define do
  sequence(:title) { |n| "title-#{n}" }
  sequence(:description) { |n| "description-#{n}" }

  factory :proposal, class: 'Proposal' do
    title { generate(:title) }
    title { generate(:description) }
    association :user, factory: :user
  end
end
