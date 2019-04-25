# frozen_string_literal: true

require 'cancancan'

module Resolvers
  class KycResolver < Resolvers::Base
    type Types::Kyc::KycType,
         null: true

    argument :id, String,
             required: true,
             description: 'Search KYC by their ID'

    def resolve(id:)
      Kyc
        .kept
        .preload(:user)
        .with_attached_identification_proof_image
        .with_attached_residence_proof_image
        .with_attached_identification_pose_image
        .find_by(id: id)
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:read, Kyc)
    end
  end
end
