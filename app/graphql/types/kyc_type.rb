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
    field :birth_date, Types::Date,
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
    field :employment_industry, Types::IndustryType,
          null: false,
          description: 'Current employment industry of the customer'
    field :income_range, Types::IncomeRangeType,
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
    field :identification_pose_image, Types::ImageType,
          null: false,
          description: <<~EOS
            Pose image where the customer is holding an ID
          EOS
  end
end
