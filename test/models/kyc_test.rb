# frozen_string_literal: true

require 'test_helper'

require 'ethereum_api'

class KycTest < ActiveSupport::TestCase
  class TestImage < ApplicationRecord
    has_one_attached :data

    validates :data,
              attached: true,
              size: { less_than: Kyc::IMAGE_SIZE_LIMIT },
              content_type: Kyc::IMAGE_FILE_TYPES
  end

  test 'image validation should work' do
    image = TestImage.new
    image.data.attach(
      io: File.open('./test/small.jpg'),
      content_type: 'image/jpg',
      filename: 'just_a_little_below.jpg'
    )

    assert image.valid?,
           'should work with an image slightly below the limit'
  end

  test 'image validation should fail safely' do
    image = TestImage.new
    image.data.attach(
      io: File.open('./test/normal.jpg'),
      content_type: 'image/jpg',
      filename: 'slightly_above.jpg'
    )

    assert_not image.valid?,
               'should fail with an image slightly above the limit'

    image.data.attach(
      io: File.open('./test/large.jpg'),
      content_type: 'image/jpg',
      filename: 'above.jpg'
    )

    assert_not image.valid?,
               'should fail with an image above the limit'

    data_url = "data:image/jpg;base64,#{Base64.strict_encode64(File.read('./test/small.jpg'))}"
    data = URI::Data.new(data_url)

    image.data.attach(
      io: StringIO.new(data.data),
      content_type: data.content_type,
      filename: 'encoding should not affect size'
    )

    assert image.valid?,
           'should work even if encoded'
  end

  test 'verify code should work' do
    code = generate(:verification_code)

    stub_verification_code(code)

    assert_equal :ok, Kyc.verify_code(code),
                 'should validate correctly'
  end

  test 'verify code should fail safely' do
    code = generate(:verification_code)

    block_number, first_two, last_two = code.split('-')
    block_number = block_number.to_i

    assert_equal :invalid_format, Kyc.verify_code(''),
                 'should validate format'

    stub_request(:post, EthereumApi::SERVER_URL).to_raise(StandardError)

    assert_equal :latest_block_not_found, Kyc.verify_code(code),
                 'should handle server error'

    forward_block_number = block_number + Kyc::MAX_BLOCK_DELAY
    expired_block_number = forward_block_number + 1

    WebMock.reset!
    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: expired_block_number.to_s(16) }.to_json)
    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(
        body: {
          result: { 'number' => expired_block_number }
        }.to_json
      )

    assert_equal :verification_expired, Kyc.verify_code(code),
                 'should handle expired verifications'

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(
        body: {
          result: {
            'number' => forward_block_number,
            'hash' => '0x#GG45678HH'
          }
        }.to_json
      )

    assert_equal :invalid_hash, Kyc.verify_code(code),
                 'should let exact block delay pass and validate incorrect hash'

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return([
                   { body: { result: { 'number' => forward_block_number } }.to_json },
                   { body: { result: nil }.to_json }
                 ])

    assert_equal :block_not_found, Kyc.verify_code(code),
                 'should handle block not found number'

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(
        body: {
          result: {
            'number' => forward_block_number,
            'hash' => "0x#{first_two}WILLWORK#{last_two}"
          }
        }.to_json
      )

    assert_equal :ok, Kyc.verify_code(code),
                 'should work accordingly'
  end

  test 'submit kyc should work' do
    user = create(:user_with_email)
    attrs = attributes_for(:submit_kyc_via_interface)

    stub_verification_code(attrs.fetch(:verification_code))

    ok, kyc = Kyc.submit_kyc(user, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Kyc, kyc,
                   'result should be a kyc'

    assert_equal :pending, user.kyc.status.to_sym,
                 'user should have a pending KYC'

    active_kyc_submitted, = Kyc.submit_kyc(user, attrs)

    assert_equal :active_kyc_submitted, active_kyc_submitted,
                 'should not allow resubmission'
  end

  test 'submit kyc should fail safely' do
    email_not_set, = Kyc.submit_kyc(
      create(:user),
      attributes_for(:submit_kyc_via_interface)
    )

    assert_equal :email_not_set, email_not_set,
                 'should fail if user email is not set'

    verification_code = '12345678-12-34'
    stub_verification_code(verification_code)

    invalid_data, = Kyc.submit_kyc(
      create(:user_with_email),
      attributes_for(:submit_kyc_via_interface, verification_code: '1111-22-31')
    )

    assert_equal :invalid_data, invalid_data,
                 'should fail if verification code is incorrect'

    invalid_data, = Kyc.submit_kyc(
      create(:user_with_email),
      attributes_for(
        :submit_kyc_via_interface,
        verification_code: verification_code,
        birthdate: (Kyc::MINIMUM_AGE - 1).years.ago
      )
    )

    assert_equal :invalid_data, invalid_data,
                 "should fail if person is not #{Kyc::MINIMUM_AGE} years old"
  end

  test 'submit kyc should work with prior submissions' do
    attrs = attributes_for(:submit_kyc_via_interface)
    rejected_kyc = create(:rejected_kyc)

    stub_verification_code(attrs.fetch(:verification_code))

    stub_request(:any, %r{kyc/approve})
      .to_return(body: { result: {} }.to_json)

    ok, new_kyc = Kyc.submit_kyc(
      rejected_kyc.user,
      attrs
    )

    assert_equal :ok, ok,
                 'should allow resubmission for rejected KYC'
    assert rejected_kyc.reload.discarded?,
           'should discard old KYC'
    assert_equal new_kyc.id, rejected_kyc.user.kyc.id,
                 'user should have new KYC'

    approved_kyc = create(:approved_kyc)

    active_kyc_submitted, = Kyc.submit_kyc(
      approved_kyc.user,
      attrs
    )

    assert_equal :active_kyc_submitted, active_kyc_submitted,
                 'should not allow resubmission for approved KYC'

    expired_kyc = create(:approved_kyc, expiration_date: Time.now)

    ok, = Kyc.submit_kyc(
      expired_kyc.user,
      attrs
    )

    assert_equal :ok, ok,
                 'should allow expired KYC resubmission'
  end

  test 'approve kyc should work' do
    officer = create(:kyc_officer_user)
    kyc = create(:pending_kyc)
    attrs = { expiration_date: generate(:future_date) }

    stub_request(:any, %r{kyc/approve})
      .to_return(body: { result: {} }.to_json)

    ok, approved_kyc = Kyc.approve_kyc(officer, kyc, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal :approved, approved_kyc.status.to_sym,
                 'kyc should be approved'
    assert_equal officer.id, approved_kyc.officer.id,
                 'approving officer should be marked '

    kyc_not_pending, = Kyc.approve_kyc(officer, kyc, attrs)

    assert_equal :kyc_not_pending, kyc_not_pending,
                 'should not allow to approve repeatedly'
  end

  test 'approve kyc should fail safely' do
    kyc = create(:pending_kyc)

    invalid_data, = Kyc.approve_kyc(
      create(:kyc_officer_user),
      kyc,
      {}
    )

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'

    unauthorized_action, = Kyc.approve_kyc(
      create(:user_with_email),
      kyc,
      expiration_date: generate(:future_date)
    )

    assert_equal :unauthorized_action, unauthorized_action,
                 'should fail with non-officers '

    kyc.discard

    unauthorized_action, = Kyc.approve_kyc(
      create(:kyc_officer_user),
      kyc,
      nil
    )

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not work with discarded kyc '
  end

  test 'reject kyc should work' do
    officer = create(:kyc_officer_user)
    kyc = create(:pending_kyc)
    attrs = { rejection_reason: generate(:rejection_reason) }

    ok, rejected_kyc = Kyc.reject_kyc(officer, kyc, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal :rejected, rejected_kyc.status.to_sym,
                 'kyc should be rejected'
    assert_equal officer.id, rejected_kyc.officer.id,
                 'rejecting officer should be marked '

    kyc_not_pending, = Kyc.reject_kyc(officer, kyc, attrs)

    assert_equal :kyc_not_pending, kyc_not_pending,
                 'should not allow to disprove repeatedly'

    kyc.discard

    unauthorized_action, = Kyc.approve_kyc(
      create(:kyc_officer_user),
      kyc,
      nil
    )

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not work with discarded kyc '
  end

  test 'reject kyc should fail safely' do
    kyc = create(:pending_kyc)

    invalid_data, = Kyc.reject_kyc(
      create(:kyc_officer_user),
      kyc,
      {}
    )

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'

    unauthorized_action, = Kyc.reject_kyc(
      create(:user_with_email),
      kyc,
      rejection_reason: generate(:rejection_reason)
    )

    assert_equal :unauthorized_action, unauthorized_action,
                 'should fail with non-officers '
  end

  test 'update KYC hashes should work' do
    hashes = create_list(:kyc, 5)
             .map do |kyc|
      { address: kyc.user.address, txhash: generate(:txhash) }
    end

    ok = Kyc.update_kyc_hashes(hashes)

    assert_equal :ok, ok

    hashes.each do |hash|
      assert_equal hash.fetch(:txhash),
                   User.find_by(address: hash.fetch(:address)).kyc.approval_txhash,
                   'approval hash should be updated'
    end
  end

  private

  def stub_verification_code(verification_code)
    WebMock.reset!

    block_number, first_two, last_two = verification_code.split('-')

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: block_number.to_i.to_s(16) }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => "0x#{first_two}1234#{last_two}" }
      }.to_json)
  end
end
