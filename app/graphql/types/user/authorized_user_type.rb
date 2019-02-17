# frozen_string_literal: true

module Types
  module User
    class AuthorizedUserType < Types::Base::BaseObject
      description 'DAO users who publish proposals and vote for them'

      field :id, ID,
            null: false,
            description: "User's ID"
      field :address, Types::Scalar::EthAddress,
            null: false,
            description: "User's ethereum address"
      field :email, String,
            null: true,
            description: "User's email"
      field :username, String,
            null: true,
            description: "User's username"
      field :display_name, String,
            null: false,
            description: <<~EOS
              Display name of the user which should be used to identify the user.
               This is just username if it is set; otherwise, this is just `user<id>`.
            EOS
      field :is_kyc_officer, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating the user is an KYC officer
               Privileges:
              - Can approve or reject KYCs
            EOS
      field :created_at, GraphQL::Types::ISO8601DateTime,
            null: false,
            description: 'Date when the proposal was published'
      field :kyc, Types::Kyc::KycType,
            null: true,
            description: 'Current KYC submission of the user'

      def display_name
        object.username.nil? ? "user#{object.uid}" : object.username
      end

      def is_kyc_officer
        object.groups.pluck(:name).member?(Group.groups[:kyc_officer])
      end
    end
  end
end
