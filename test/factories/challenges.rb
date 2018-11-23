# frozen_string_literal: true

FactoryBot.define do
  sequence(:challenge) { |_| rand(36 * 10).to_s(10) }
end
