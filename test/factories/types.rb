# frozen_string_literal: true

FactoryBot.define do
  sequence(:search_kyc_field) { |_| Types::Enum::SearchKycFieldEnum.values.map(&:first).sample }
  sequence(:sort_by) { |_| Types::Enum::SortByEnum.values.map(&:first).sample }
end
