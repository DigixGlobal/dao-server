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
      field :reputation_point, Types::Scalar::BigNumber,
            null: false,
            description: <<~EOS
              The user's reputation in participating in the system.
            EOS
      field :quarter_point, Types::Scalar::BigNumber,
            null: false,
            description: <<~EOS
              The user's accumulated points in the quarter.
            EOS
      field :is_kyc_officer, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating the user is an KYC officer

              Privileges:
              - Can approve or reject KYCs
            EOS
      field :is_forum_admin, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating the user is a forum admin

              Privileges:
              - Can ban and unban users
              - Can ban and unban comments
            EOS
      field :can_comment, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating the if the user can comment in projects
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
        object.groups&.pluck(:name)&.member?(Group.groups[:kyc_officer])
      end

      def is_forum_admin
        object.groups&.pluck(:name)&.member?(Group.groups[:forum_admin])
      end

      def id
        object.uid
      end

      def can_comment
        !object.is_banned
      end

      def quarter_point
        Types::Proposal::LazyPoints.new(context, object, :quarter_point)
      end

      def reputation_point
        Types::Proposal::LazyPoints.new(context, object, :reputation_point)
      end
    end
  end
end
