# frozen_string_literal: true

module Types
  class KycType < Types::BaseObject
    description "A customer's KYC submission"

    field :status, Types::KycStatusEnum,
          null: false,
          description: 'Current status or state of the KYC'
    field :first_name, String,
          null: false,
          description: 'First name of the customer'
    field :last_name, String,
          null: false,
          description: 'Last name of the customer'
    field :gender, Types::GenderEnum,
          null: false,
          description: 'Gender of the customer'
    field :birthdate, Types::Date,
          null: false,
          description: 'Birth date of the customer'
    field :nationality, Types::CountryValue,
          null: false,
          description: "Country of the customer's nationality"
    field :phone_number, String,
          null: false,
          description: 'Phone number of the customer including the country code'
    field :employment_status, Types::EmploymentStatusEnum,
          null: false,
          description: 'Current employment status of the customer'
    field :employment_industry, Types::IndustryValue,
          null: false,
          description: 'Current employment industry of the customer'
    field :income_range, Types::IncomeRangeValue,
          null: false,
          description: 'Income range per annum of the customer'
    field :identification_proof, Types::IdentificationProofType,
          null: false,
          description: <<~EOS
            ID image such as passport or national ID of the customer
          EOS
    field :residence_proof, Types::ResidenceProofType,
          null: false,
          description: <<~EOS
            Residential proof such as utility bills of the customer
          EOS
    field :identification_pose, Types::IdentificationPoseType,
          null: false,
          description: <<~EOS
            Pose image where the customer is holding an ID
          EOS

    def identification_proof
      {
        number: object['identification_proof_number'],
        type: object['identification_proof_type'],
        expiration_date: object['identification_proof_expiration_date'],
        image: encode_attachment(object.identification_proof_image.attachment)
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
        image: encode_attachment(object.residence_proof_image.attachment)
      }
    end

    def identification_pose
      {
        verification_code: object['verification_code'],
        image: encode_attachment(object.identification_pose_image.attachment)
      }
    end

    private

    def encode_attachment(attachment)
      return nil unless attachment && (blob = attachment.blob)

      {
        filename: blob.filename,
        file_size: blob.byte_size,
        content_type: blob.content_type,
        data_url: "data:#{blob.content_type};base64,#{Base64.encode64(blob.download).rstrip}"
      }
    end
  end
end
