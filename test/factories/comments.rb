# frozen_string_literal: true

FactoryBot.define do
  sequence(:comment) { |n| "comment-#{n}" }

  factory :proposal_comment, class: 'Comment' do
    comment { generate(:comment) }
    association :proposal, factory: :proposal
    association :user, factory: :user
  end
end
