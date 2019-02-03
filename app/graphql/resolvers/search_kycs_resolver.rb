# frozen_string_literal: true

module Resolvers
  class SearchKycsResolver < Resolvers::Base
    type Types::KycPaginatedConnectionType,
         null: false

    argument :page, Types::PositiveInteger,
             required: false,
             default_value: 1,
             description: <<~EOS
               Batch page number for the collection.

               If the page number exceeds the total count
               then it returns an empty data
             EOS
    argument :page_size, Types::PositiveInteger,
             required: false,
             default_value: 30,
             description: 'Number of records to fetch per page'
    argument :status, Types::KycStatusEnum,
             required: false,
             description: 'Filter KYCs by their status'

    def resolve(page:, page_size:, status: nil)
      source = Kyc
               .kept
               .order(created_at: :asc)
               .preload(:user)
               .with_attached_identification_proof_image
               .with_attached_residence_proof_image
               .with_attached_identification_pose_image

      query = status ? source.where(status: status) : source

      items = query.page(page).per(page_size)

      connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(items)
      connection_class.new(
        items,
        total_count: items.total_count,
        total_page: items.total_pages,
        has_next_page: items.first_page?,
        has_previous_page: items.last_page?
      )
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:read, Kyc)
    end
  end
end
