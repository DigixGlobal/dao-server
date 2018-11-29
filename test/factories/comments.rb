# frozen_string_literal: true

FactoryBot.define do
  sequence(:comment_body) { |n| "comment-#{n}" }

  factory :comment, class: 'Comment' do
    body { generate(:comment_body) }
    stage { generate(:proposal_stage) }
    association :proposal, factory: :proposal
    association :user, factory: :user
  end

  factory :proposal_comment, class: 'Object' do
    body { generate(:comment_body) }
  end
end
