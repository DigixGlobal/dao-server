# frozen_string_literal: true

module Types
  module Kyc
    class KycType < Types::Base::BaseObject
      description "A customer's KYC submission"

      field :id, ID,
            null: false,
            description: 'KYC ID'
      field :expiration_date, Types::Scalar::Date,
            null: true,
            description: <<~EOS
              Expiration date of the KYC.
               After this date, the KYC is marked `EXPIRED`
              and the user should submit again.
            EOS
      field :status, Types::Enum::KycStatusEnum,
            null: false,
            description: <<~EOS
              Current status or state of the KYC.
               If the KYC is approved and it is after the expiration date,
               the status is expired.
            EOS
      field :is_approved, Boolean,
            null: false,
            description: 'A flag if the kyc is `APPROVED`'
      field :rejection_reason, Types::Scalar::RejectionReasonValue,
            null: true,
            description: <<~EOS
              If the status is `REJECTED`, this is reason it was rejected.
            EOS
      field :user_id, String,
            null: false,
            description: 'Customer user ID'
      field :eth_address, Types::Scalar::EthAddress,
            null: false,
            description: 'Customer ethereum address'
      field :email, String,
            null: false,
            description: 'Customer email'
      field :first_name, String,
            null: false,
            description: 'First name of the customer'
      field :last_name, String,
            null: false,
            description: 'Last name of the customer'
      field :gender, Types::Enum::GenderEnum,
            null: false,
            description: 'Gender of the customer'
      field :birthdate, Types::Scalar::Date,
            null: false,
            description: 'Birth date of the customer'
      field :nationality, Types::Scalar::CountryValue,
            null: false,
            description: "Country of the customer's nationality"
      field :phone_number, String,
            null: false,
            description: 'Phone number of the customer including the country code'
      field :employment_status, Types::Enum::EmploymentStatusEnum,
            null: false,
            description: 'Current employment status of the customer'
      field :employment_industry, Types::Scalar::IndustryValue,
            null: false,
            description: 'Current employment industry of the customer'
      field :income_range, Types::Scalar::IncomeRangeValue,
            null: false,
            description: 'Income range per annum of the customer'
      field :identification_proof, Types::Kyc::IdentificationProofType,
            null: false,
            description: <<~EOS
              ID image such as passport or national ID of the customer
            EOS
      field :residence_proof, Types::Kyc::ResidenceProofType,
            null: false,
            description: <<~EOS
              Residential proof such as utility bills of the customer
            EOS
      field :identification_pose, Types::Kyc::IdentificationPoseType,
            null: false,
            description: <<~EOS
              Pose image where the customer is holding an ID
            EOS
      field :ip_addresses, [String],
            null: false,
            description: <<~EOS
              A list of IP addresses used by the customer.
               Currently, IP address is not tracked so this is an empty list.
            EOS
      field :created_at, GraphQL::Types::ISO8601DateTime,
            null: false,
            description: 'Date when the KYC was submitted'
      field :updated_at, GraphQL::Types::ISO8601DateTime,
            null: false,
            description: 'Date when the KYC was last touched or modified'

      def user_id
        object.user.id
      end

      def email
        object.user.email
      end

      def eth_address
        object.user.address
      end

      def is_approved
        object.status.to_sym == :pending
      end

      def status
        if object.status.to_sym == :approved
          object.expired? ? 'expired' : 'approved'
        else
          object.status
        end
      end

      def ip_addresses
        []
      end

      def identification_proof
        {
          number: object['identification_proof_number'],
          type: object['identification_proof_type'],
          expiration_date: object['identification_proof_expiration_date'],
          image: object.identification_proof_image
        }
      end

      def residence_proof
        {
          residence: {
            address: object['address'],
            address_details: object['address_details'],
            city: object['city'],
            country: object['country'],
            state: object['country'],
            postal_code: object['postal_code']
          },
          type: object['residence_proof_type'],
          image: object.residence_proof_image
        }
      end

      def identification_pose
        {
          verification_code: object['verification_code'],
          image: object.identification_pose_image
        }
      end

      private

      def encode_attachment(attachment)
        return nil unless attachment && (blob = attachment.blob)

        {
          filename: blob.filename,
          file_size: blob.byte_size,
          content_type: blob.content_type,
          data_url: "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
        }
      end
    end
  end
end
