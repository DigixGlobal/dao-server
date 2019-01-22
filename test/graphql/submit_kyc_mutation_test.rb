# frozen_string_literal: true

require 'test_helper'

class SubmitKycMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation ($firstName: String!, $lastName: String!, $gender: GenderEnum!, $birthdate: Date!, $birthCountry: LegalCountryValue!, $nationality: LegalCountryValue!, $phoneNumber: String!, $employmentStatus: EmploymentStatusEnum!, $employmentIndustry: IndustryValue!, $incomeRange: IncomeRangeValue!, $identificationProofNumber: String!, $identificationProofType: IdentificationProofTypeEnum!, $identificationProofExpirationDate: Date!, $identificationProofDataUrl: DataUrl!, $residenceProofType: ResidenceProofTypeEnum!, $country: LegalCountryValue!, $address: String!, $addressDetails: String, $city: String!, $state: String!, $postalCode: String!, $residenceProofDataUrl: DataUrl!, $identificationPoseVerificationCode: String!, $identificationPoseDataUrl: DataUrl!) {
      submitKyc(input: {firstName: $firstName, lastName: $lastName, gender: $gender, birthdate: $birthdate, birthCountry: $birthCountry, nationality: $nationality, phoneNumber: $phoneNumber, employmentStatus: $employmentStatus, employmentIndustry: $employmentIndustry, incomeRange: $incomeRange, identificationProofNumber: $identificationProofNumber, identificationProofType: $identificationProofType, identificationProofExpirationDate: $identificationProofExpirationDate, identificationProofDataUrl: $identificationProofDataUrl, residenceProofType: $residenceProofType, country: $country, address: $address, addressDetails: $addressDetails, city: $city, state: $state, postalCode: $postalCode, residenceProofDataUrl: $residenceProofDataUrl, identificationPoseVerificationCode: $identificationPoseVerificationCode, identificationPoseDataUrl: $identificationPoseDataUrl}) {
        kyc {
          status
          firstName
          lastName
          gender
          birthdate
          nationality
          phoneNumber
          employmentStatus
          employmentIndustry
          incomeRange
          identificationProof {
            number
            expirationDate
            type
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
          residenceProof {
            residence {
              address
              addressDetails
              city
              country
              postalCode
              state
            }
            type
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
          identificationPose {
            verificationCode
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'submit kyc mutation should work' do
    user = create(:user_with_email)
    attrs = normalize_attributes(attributes_for(:submit_kyc_via_mutation))

    block_number, first_two, last_two = attrs['identificationPoseVerificationCode'].split('-')

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: block_number.to_i.to_s(16) }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => "0x#{first_two}1234#{last_two}" }
      }.to_json)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['submitKyc']['errors'],
                 'should have no errors'

    data = result['data']['submitKyc']['kyc']

    assert_equal 'PENDING', data['status'],
                 'should be pending'

    resubmission_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_not_empty resubmission_result['data']['submitKyc']['errors'],
                     'should not allow resubmission pending kycs'
  end

  test 'should fail safely' do
    attrs = normalize_attributes(attributes_for(:submit_kyc_via_mutation))

    unset_email_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: attrs
    )

    assert_not_empty unset_email_result['data']['submitKyc']['errors'],
                     'should not allow users without email to submit a KYC'

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: 'IMPOSSIBLE_BLOCK' }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => '0xINVALID_HASH' }
      }.to_json)

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user_with_email) },
      variables: attrs
    )

    assert_not_empty empty_result['data']['submitKyc']['errors'],
                     'should fail with empty data'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end

  private

  def normalize_attributes(attrs)
    attrs[:birthdate] = attrs[:birthdate].strftime('%F')
    attrs[:identification_proof_expiration_date] = attrs[:identification_proof_expiration_date].strftime('%F')

    attrs[:gender] = attrs[:gender].upcase
    attrs[:employment_status] = attrs[:employment_status].upcase
    attrs[:identification_proof_type] = attrs[:identification_proof_type].upcase
    attrs[:residence_proof_type] = attrs[:residence_proof_type].upcase

    attrs.to_h.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end
end
