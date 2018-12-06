# frozen_string_literal: true

FactoryBot.define do
  factory :comment_like, class: 'CommentLike' do
    association :user, factory: :user
    association :comment, factory: :comment
  end
end
