# frozen_string_literal: true

module Mutations
  class SubmitKycMutation < Types::Base::BaseMutation
    description <<~EOS
      As the current user, submit a KYC to access more features of the app.

      To submit the KYC, the user must already have his email set.
      Once submitted, a KYC admin will check the facts and
       will either approve or reject it.
      If rejected with a reason or expired over time,
       the user is encouraged to submit another KYC through this operation.
    EOS

    argument :first_name, String,
             required: true,
             description: <<~EOS
               First name of the customer.

               Validations:
               - Maximum of 150 characters
             EOS
    argument :last_name, String,
             required: true,
             description: <<~EOS
               Last name of the customer.

               Validations:
               - Maximum of 150 characters
             EOS
    argument :gender, Types::Enum::GenderEnum,
             required: true,
             description: 'Gender of the customer'
    argument :birthdate, Types::Scalar::Date,
             required: true,
             description: <<~EOS
               Birth date of the customer.

               Validations:
               - Must be 18 years or older
             EOS
    argument :birth_country, Types::Scalar::LegalCountryValue,
             required: true,
             description: "Legal/non-blocked country of the customer's birth"
    argument :nationality, Types::Scalar::LegalCountryValue,
             required: true,
             description: "Country of the customer's nationality"
    argument :phone_number, String,
             required: true,
             description: <<~EOS
               Phone number of the customer including the country code.

               Validations:
               - Maximum of 20 characters
               - Can optionally start with `+`
               - Must be comprised of digits (`0-9`) or dashes (`-`)
               - Must not start or end with a dash
             EOS
    argument :employment_status, Types::Enum::EmploymentStatusEnum,
             required: true,
             description: 'Current employment status of the customer'
    argument :employment_industry, Types::Scalar::IndustryValue,
             required: true,
             description: 'Current employment industry of the customer'
    argument :income_range, Types::Scalar::IncomeRangeValue,
             required: true,
             description: 'Income range per annum of the customer'
    argument :identification_proof_number, String,
             required: true,
             description: <<~EOS
               Code/number of the ID.

               Validations:
               - Maximum of 50 characters
             EOS
    argument :identification_proof_type, Types::Enum::IdentificationProofTypeEnum,
             required: true,
             description: 'Type of ID used'
    argument :identification_proof_expiration_date, Types::Scalar::Date,
             required: true,
             description: <<~EOS
               Expiration date of the ID.

               Validations:
               - Must not be expired or a future date
             EOS
    argument :identification_proof_data_url, Types::Scalar::DataUrl,
             required: true,
             description: <<~EOS
               Image data URL to prove personal identification.

               Validations:
               - Maximum of 10 MB size
               - JPEG or PNG files only
             EOS
    argument :country, Types::Scalar::LegalCountryValue,
             required: true,
             description: 'Country address of the customer'
    argument :address, String,
             required: true,
             description: <<~EOS
               Descriptive combination of unit/block/house number and street name of the customer.

               Validations:
               - Maximum of 1000 characters
             EOS
    argument :address_details, String,
             required: false,
             description: <<~EOS
               Extra descriptions about the address such as landmarks or corners.

               Validations:
               - Maximum of 1000 characters
             EOS
    argument :city, String,
             required: true,
             description: <<~EOS
               City address of the customer.

               Validations:
               - Maximum of 250 characters
             EOS
    argument :state, String,
             required: true,
             description: <<~EOS
               State or division addressof the customer.

               Validations:
               - Maximum of 250 characters
             EOS
    argument :postal_code, String,
             required: true,
             description: <<~EOS
               Postal code address of the customer.

               Validations:
               - Maximum of 12 characters
               - Must be comprised of alphanumeric characters (`A-Z0-9`), spaces and dashes (`-`)
               - Must not end or begin with a dash
             EOS
    argument :residence_proof_type, Types::Enum::ResidenceProofTypeEnum,
             required: true,
             description: 'Kind/type of proof presented for residence'
    argument :residence_proof_data_url, Types::Scalar::DataUrl,
             required: true,
             description: <<~EOS
               Image data URL to prove personal residence

               Validations:
               - Maximum of 10 MB size
               - JPEG or PNG files only
             EOS
    argument :identification_pose_verification_code, String,
             required: true,
             description: <<~EOS
               The verification code presented in the identification pose.

               It is comprised of `<block number>-<first two digits of the block hash>`-<last two of the hash>`

               Validations:
               - Block number be 20 blocks old
             EOS
    argument :identification_pose_data_url, Types::Scalar::DataUrl,
             required: true,
             description: <<~EOS
               Image data URL to prove identification is valid

               Validations:
               - Maximum of 10 MB size
               - JPEG or PNG files only
             EOS

    field :kyc, Types::Kyc::KycType,
          null: true,
          description: 'New kyc submission'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Email not sent
            - Already have a pending or active KYC
          EOS

    def resolve(**attrs)
      user = context.fetch(:current_user)
      this_user = User.find(user.id)

      new_attrs = kyc_attrs(attrs)

      result, user_or_errors = Kyc.submit_kyc(this_user, new_attrs)

      key = :kyc

      case result
      when :email_not_set
        form_error(key, 'email', 'Email not set')
      when :active_kyc_submitted
        form_error(key, '_', 'Already have a pending or active KYC')
      when :invalid_data
        model_errors(key, user_or_errors)
      when :ok
        model_result(key, user_or_errors)
      end
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    private

    def kyc_attrs(attrs)
      base_attrs = attrs.except(
        :identification_proof_data_url,
        :identification_pose_data_url,
        :residence_proof_data_url,
        :identification_pose_verification_code
      )

      base_attrs.merge(
        verification_code: attrs.fetch(:identification_pose_verification_code),
        identification_proof_image: data_url_to_image(attrs.fetch(:identification_proof_data_url)),
        identification_pose_image: data_url_to_image(attrs.fetch(:identification_pose_data_url)),
        residence_proof_image: data_url_to_image(attrs.fetch(:residence_proof_data_url))
      )
    end

    def data_url_to_image(data_url)
      return nil unless data_url

      {
        data: data_url.data,
        content_type: data_url.content_type
      }
    end
  end
end
