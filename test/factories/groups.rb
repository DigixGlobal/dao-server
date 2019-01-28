# frozen_string_literal: true

FactoryBot.define do
  factory :group, class: 'Group' do
    name { |_| Group.groups.values.sample }
  end
end
