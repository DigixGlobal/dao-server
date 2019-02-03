# frozen_string_literal: true

require 'ethereum_api'
require 'info_api'

class Kyc < ApplicationRecord
  MAX_BLOCK_DELAY = Rails.configuration.ethereum['max_block_delay'].to_i
  MINIMUM_AGE = 18
  VERIFICATION_PATTERN = /\A(\d+)-(\d{2})-(\d{2})\Z/.freeze
  IMAGE_SIZE_LIMIT = 10.megabytes
  IMAGE_FILE_TYPES = ['image/jpeg', 'image/jpeg', 'image/png'].freeze

  enum status: { pending: 1, rejected: 2, approved: 3 }
  enum gender: { male: 1, female: 2 }
  enum employment_status: { employed: 0, self_employed: 1, unemployed: 2 }
  enum identification_proof_type: { passport: 0, national_id: 1, identity_card: 2 }, _prefix: :identification
  enum residence_proof_type: { utility_bill: 0, bank_statement: 1 }, _prefix: :residence

  belongs_to :user
  belongs_to :officer,
             class_name: 'User',
             foreign_key: :officer_id,
             optional: true

  has_one_attached :residence_proof_image
  has_one_attached :identification_proof_image
  has_one_attached :identification_pose_image

  include Discard::Model

  validates :first_name,
            presence: true,
            length: { maximum: 150 }
  validates :last_name,
            presence: true,
            length: { maximum: 150 }
  validates :gender,
            presence: true
  validates :birthdate,
            presence: true,
            timeliness: { on_or_before: -> { MINIMUM_AGE.years.ago } }
  validates :birth_country,
            presence: true,
            country: true
  validates :nationality,
            presence: true,
            country: true
  validates :nationality,
            presence: true,
            country: true
  validates :phone_number,
            presence: true,
            length: { maximum: 20 },
            format: { with: /\A(\+)?[0-9][0-9\-]+[0-9]\z/ }
  validates :employment_status,
            presence: true
  validates :employment_industry,
            presence: true
  validates :income_range,
            presence: true
  validates :identification_proof_number,
            presence: true,
            length: { maximum: 50 }
  validates :identification_proof_expiration_date,
            presence: true,
            timeliness: { on_or_after: :today }
  validates :country,
            presence: true,
            country: true
  validates :address,
            presence: true,
            length: { maximum: 1000 }
  validates :address_details,
            presence: false,
            length: { maximum: 1000 }
  validates :city,
            presence: true,
            length: { maximum: 250 }
  validates :state,
            presence: true,
            length: { maximum: 250 }
  validates :postal_code,
            presence: true,
            length: { maximum: 12 },
            format: { with: /\A[a-z0-9][a-z0-9\-\s]{0,10}[a-z0-9]\z/i }
  validates :residence_proof_type,
            presence: true
  validates :verification_code,
            presence: true,
            format: { with: VERIFICATION_PATTERN }
  validates :identification_proof_image,
            attached: true,
            size: { less_than: IMAGE_SIZE_LIMIT },
            content_type: IMAGE_FILE_TYPES
  validates :residence_proof_image,
            attached: true,
            size: { less_than: IMAGE_SIZE_LIMIT },
            content_type: IMAGE_FILE_TYPES
  validates :identification_pose_image,
            attached: true,
            size: { less_than: IMAGE_SIZE_LIMIT },
            content_type: IMAGE_FILE_TYPES
  validates :expiration_date,
            if: proc { |kyc| kyc.status.to_sym == :approved },
            timeliness: { on_or_after: :today }
  validates :rejection_reason,
            if: proc { |kyc| kyc.status.to_sym == :rejected },
            rejection_reason: true
  validates :approval_txhash,
            presence: false

  def expired?
    Time.now > expiration_date.to_time
  end

  class << self
    def submit_kyc(user, attrs)
      this_user = User.find(user.id)

      return [:email_not_set, nil] unless this_user.email

      if (this_kyc = this_user.kyc)
        kyc_status = this_kyc.status.to_sym
        if kyc_status == :pending
          return [:active_kyc_submitted, nil]
        elsif kyc_status == :approved && !this_kyc.expired?
          return [:active_kyc_submitted, nil]
        end
      end

      base_attrs = attrs.except(
        :identification_proof_image,
        :residence_proof_image,
        :identification_pose_image
      )

      kyc = Kyc.new(base_attrs)
      kyc.user_id = this_user.id
      kyc.status = :pending

      verification_error =
        case verify_code(kyc.verification_code)
        when :invalid_format then
          'has invalid format' # Should not happen
        when :latest_block_not_found then
          'could not be verified'
        when :verification_expired then
          'is expired'
        when :block_not_found then
          'could not be found'
        when :invalid_hash then
          'is incorrect'
        end

      if verification_error
        kyc.errors.add(:verification_code, verification_error)
        return [:invalid_data, kyc.errors]
      end

      encode_image(kyc, :identification_proof_image, attrs[:identification_proof_image])
      encode_image(kyc, :residence_proof_image, attrs[:residence_proof_image])
      encode_image(kyc, :identification_pose_image, attrs[:identification_pose_image])

      return [:invalid_data, kyc.errors] unless kyc.valid?
      return [:database_error, kyc.errors] unless kyc.save

      this_kyc&.discard

      [:ok, kyc]
    end

    def verify_code(verification_code)
      unless verification_code&.match?(VERIFICATION_PATTERN)
        return :invalid_format
      end

      block_number, first_two, last_two =
        verification_code.match(VERIFICATION_PATTERN).captures

      block_number = block_number.to_i
      block_hash = "0x#{block_number.to_s(16)}"

      ok_latest, latest_block = EthereumApi.get_latest_block

      return :latest_block_not_found unless ok_latest == :ok && latest_block

      unless (latest_block.fetch('number', '').to_i - block_number) <= MAX_BLOCK_DELAY
        return :verification_expired
      end

      ok_this, this_block = EthereumApi.get_block_by_block_number(block_hash)

      return :block_not_found unless ok_this == :ok && this_block

      this_hash = this_block.fetch('hash', '').slice(2..-1)

      unless this_hash.slice(0, 2) == first_two &&
             this_hash.slice(-2, 2) == last_two
        return :invalid_hash
      end

      :ok
    end

    def approve_kyc(officer, kyc, attrs)
      this_officer = User.find(officer.id)
      this_kyc = Kyc.find(kyc.id)

      return [:unauthorized_action, nil] if this_kyc.discarded?

      unless Ability.new(this_officer).can?(:approve, Kyc, kyc)
        return [:unauthorized_action, nil]
      end

      return [:kyc_not_pending, nil] unless this_kyc.status.to_sym == :pending

      unless this_kyc.update_attributes(
        status: :approved,
        officer: this_officer,
        **attrs
      )
        return [:invalid_data, this_kyc.errors] unless this_kyc.valid?
      end

      Rails.logger.info 'Updating info-server with this approved kyc'
      info_result, info_data_or_error = InfoApi.approve_kyc(this_kyc)
      unless info_result == :ok
        Rails.logger.debug "Failed to updated info-server: #{info_data_or_error}"
      end

      [:ok, this_kyc]
    end

    def reject_kyc(officer, kyc, attrs)
      this_officer = User.find(officer.id)
      this_kyc = Kyc.find(kyc.id)

      return [:unauthorized_action, nil] if this_kyc.discarded?

      unless Ability.new(this_officer).can?(:reject, Kyc, kyc)
        return [:unauthorized_action, nil]
      end

      return [:kyc_not_pending, nil] unless this_kyc.status.to_sym == :pending

      unless this_kyc.update_attributes(
        status: :rejected,
        officer: this_officer,
        **attrs
      )
        return [:invalid_data, this_kyc.errors] unless this_kyc.valid?
      end

      [:ok, this_kyc]
    end

    def update_kyc_hashes(hashes)
      ActiveRecord::Base.transaction do
        hashes.each do |hash|
          if (user = User.find_by(address: hash.fetch(:address, ''))) &&
             (kyc = user.kyc)
            kyc.update_attribute(:approval_txhash, hash.fetch(:txhash, ''))
          end
        end
      end

      :ok
    end

    private

    def encode_image(kyc, key, image)
      attachment = kyc.method(key).call
      attachment.attach(
        io: StringIO.new(image[:data]),
        content_type: image[:content_type],
        filename: "#{key}_#{kyc.user.uid}"
      )
    end
  end
end
