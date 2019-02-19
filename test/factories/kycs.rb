# frozen_string_literal: true

require 'faker'

file_path = Rails.root.join('test', 'test-image.jpeg')
file_data = File.read(file_path)
countries = Rails.configuration.countries
                 .select { |country| country['blocked'] == false }
                 .map { |country| country['value'] }
income_ranges = Rails.configuration.income_ranges
                     .map { |income_range| income_range['value'] }
industries = Rails.configuration.industries
                  .map { |industry| industry['value'] }
rejection_reasons = Rails.configuration.rejection_reasons
                         .map { |rejection_reason| rejection_reason['value'] }

FactoryBot.define do
  sequence(:kyc_status) { |_| Kyc.statuses.keys.sample }
  sequence(:person_name) { |_| Faker::Name.first_name }
  sequence(:past_date) { |_| Time.at(rand * Time.now.to_i).to_date }
  sequence(:birthdate) { |_| Faker::Date.birthday(Kyc::MINIMUM_AGE) }
  sequence(:future_date) { |_| Faker::Date.forward(1000) }
  sequence(:gender) { |_| Kyc.genders.keys.sample }
  sequence(:country) { |_| countries.sample }
  sequence(:phone_number) { |n| "#{['', '+'].sample}631-234567#{n}" }
  sequence(:employment_status) { |_| Kyc.employment_statuses.keys.sample }
  sequence(:employment_industry) { |_| industries.sample }
  sequence(:income_range) { |_| income_ranges.sample }
  sequence(:identification_proof_number) { |_| SecureRandom.hex }
  sequence(:identification_proof_type) do |_|
    Kyc.identification_proof_types.keys.sample
  end
  sequence(:identification_proof_filename) do |n|
    "identification-proof#{n}.jpg"
  end
  sequence(:place) { |_| Faker::Address.street_address }
  sequence(:postal_code) { |_| Faker::Address.postcode }
  sequence(:residence_proof_type) { |_| Kyc.residence_proof_types.keys.sample }
  sequence(:residence_proof_filename) { |n| "residence-proof#{n}.jpg" }
  sequence(:identification_pose_type) do |_|
    Kyc.identification_pose_types.keys.sample
  end
  sequence(:identification_pose_filename) { |n| "identification-pose#{n}.jpg" }
  sequence(:verification_code) do |_|
    "#{Random.rand(9_999_000..9_999_900)}-aB-9F"
  end

  sequence(:image_url) do |_|
    data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='
    "data:image/png;base64,#{data}"
  end
  sequence(:image_data) do |_|
    {
      content_type: 'image/jpeg',
      data: file_data
    }
  end
  sequence(:rejection_reason) { |_| rejection_reasons.sample }

  sequence(:positive_int) { |_| SecureRandom.random_number(100_000) }

  factory :kyc, class: 'Kyc' do
    status { generate(:kyc_status) }
    first_name { generate(:person_name) }
    last_name { generate(:person_name) }
    birthdate { generate(:birthdate) }
    gender { generate(:gender) }
    birth_country { generate(:country) }
    nationality { generate(:country) }
    phone_number { generate(:phone_number) }
    employment_status { generate(:employment_status) }
    employment_industry { generate(:employment_industry) }
    income_range { generate(:income_range) }
    identification_proof_type { generate(:identification_proof_type) }
    identification_proof_expiration_date { generate(:future_date) }
    identification_proof_number { generate(:identification_proof_number) }
    country { generate(:country) }
    address { generate(:place) }
    address_details { generate(:place) }
    city { generate(:place) }
    state { generate(:place) }
    postal_code { generate(:postal_code) }
    residence_proof_type { generate(:residence_proof_type) }
    verification_code { generate(:verification_code) }
    expiration_date { generate(:future_date) }
    rejection_reason { generate(:rejection_reason) }

    association :user, factory: :user_with_email

    before(:create) do |kyc|
      kyc.identification_proof_image.attach(
        io: File.open(file_path),
        filename: generate(:identification_proof_filename),
        content_type: 'image/jpeg'
      )

      kyc.residence_proof_image.attach(
        io: File.open(file_path),
        filename: generate(:residence_proof_filename),
        content_type: 'image/jpeg'
      )

      kyc.identification_pose_image.attach(
        io: File.open(file_path),
        filename: generate(:identification_pose_filename),
        content_type: 'image/jpeg'
      )
    end

    factory :pending_kyc do
      status { :pending }
      expiration_date { nil }
      rejection_reason { nil }
    end

    factory :approved_kyc do
      status { :approved }
      association :officer, factory: :kyc_officer_user
    end

    factory :rejected_kyc do
      status { :rejected }
      association :officer, factory: :kyc_officer_user
    end
  end

  factory :submit_kyc, class: 'Hash' do
    first_name { generate(:person_name) }
    last_name { generate(:person_name) }
    birthdate { generate(:birthdate) }
    gender { |_| generate(:gender) }
    birth_country { generate(:country) }
    nationality { generate(:country) }
    phone_number { generate(:phone_number) }
    employment_status { |_| generate(:employment_status) }
    employment_industry { generate(:employment_industry) }
    income_range { generate(:income_range) }
    identification_proof_type { |_| generate(:identification_proof_type) }
    identification_proof_expiration_date { generate(:future_date) }
    identification_proof_number { generate(:identification_proof_number) }
    country { generate(:country) }
    address { generate(:place) }
    address_details { generate(:place) }
    city { generate(:place) }
    state { generate(:place) }
    postal_code { generate(:postal_code) }
    residence_proof_type { |_| generate(:residence_proof_type) }

    factory :submit_kyc_via_mutation do
      identification_proof_data_url { generate(:image_url) }
      residence_proof_data_url { generate(:image_url) }
      identification_pose_verification_code { generate(:verification_code) }
      identification_pose_data_url { generate(:image_url) }
    end

    factory :submit_kyc_via_interface do
      identification_proof_image { generate(:image_data) }
      residence_proof_image { generate(:image_data) }
      verification_code { generate(:verification_code) }
      identification_pose_image { generate(:image_data) }
    end
  end

  factory :search_kycs, class: 'Hash' do
    page { generate(:positive_int) }
    per_page { generate(:positive_int) }
    status { generate(:kyc_status) }
  end
end
