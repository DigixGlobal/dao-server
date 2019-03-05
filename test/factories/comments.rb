# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  sequence(:comment_body) { |_| Faker::Movie.quote }
  sequence(:thread_sorting) { |_| %i[oldest latest].sample }

  factory :comment, class: 'Comment' do
    body { generate(:comment_body) }
    stage { generate(:proposal_stage) }
    association :user, factory: :user

    factory :comment_with_likes do
      transient do
        like_count { 40 }
      end

      after(:create) do |comment, evaluator|
        like_count = evaluator.like_count

        count = Random.rand(1..like_count)
        count.times do
          create(:comment_like, comment: comment)
        end

        comment.update(likes: count)
      end
    end
  end

  factory :proposal_comment, class: 'Object' do
    body { generate(:comment_body) }
  end

  factory :comment_thread, class: 'Object' do
    stage { generate(:proposal_stage) }
    sort_by { generate(:thread_sorting) }
  end
end
