# frozen_string_literal: true

file_path = Rails.root.join('test', 'test-image.jpeg')

FactoryBot.define do
  sequence(:kyc_status) { |_| Kyc.statuses.keys.sample }
  sequence(:employment_status) { |_| Kyc.employment_statuses.keys.sample }
  sequence(:identification_proof_type) { |_| Kyc.identification_proof_types.keys.sample }
  sequence(:residence_proof_type) { |_| Kyc.residence_proof_types.keys.sample }

  factory :kyc, class: 'Kyc' do
    status { generate(:kyc_status) }
    association :user, factory: :user

    after(:create) do |kyc|
      kyc.identification_pose_image.attach(File.new(file_path))
    end
  end
end
