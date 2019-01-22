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

    data_url = "data:image/jpg;base64,#{Base64.encode64(File.read('./test/small.jpg')).rstrip}"
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

    block_number, first_two, last_two = code.split('-')

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: block_number.to_i.to_s(16) }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => "0x#{first_two}1234#{last_two}" }
      }.to_json)

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

    block_number, first_two, last_two = attrs.fetch(:verification_code).split('-')

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: block_number.to_i.to_s(16) }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => "0x#{first_two}1234#{last_two}" }
      }.to_json)

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
    block_number, first_two, last_two = verification_code.split('-')

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_blockNumber/)
      .to_return(body: { result: block_number.to_i.to_s(16) }.to_json)

    stub_request(:post, EthereumApi::SERVER_URL)
      .with(body: /eth_getBlockByNumber/)
      .to_return(body: {
        result: { 'hash' => "0x#{first_two}1234#{last_two}" }
      }.to_json)

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
end
