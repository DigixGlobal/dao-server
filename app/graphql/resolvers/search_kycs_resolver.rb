# frozen_string_literal: true

require 'cancancan'

module Resolvers
  class SearchKycsResolver < Resolvers::Base
    type Types::Kyc::KycPaginatedConnectionType,
         null: false

    argument :page, Types::Scalar::PositiveInteger,
             required: false,
             default_value: 1,
             description: <<~EOS
               Batch page number for the collection.

               If the page number exceeds the total count
               then it returns an empty data
             EOS
    argument :page_size, Types::Scalar::PositiveInteger,
             required: false,
             default_value: 30,
             description: 'Number of records to fetch per page. Default is 30 records per page.'
    argument :status, Types::Enum::KycStatusEnum,
             required: false,
             default_value: nil,
             description: 'Filter KYCs by their status'
    argument :sort, Types::Enum::SearchKycFieldEnum,
             required: false,
             default_value: 'updated_at',
             description: <<~EOS
               Sort by field for KYC. Default is `LAST_UPDATED`.
             EOS
    argument :sort_by, Types::Enum::SortByEnum,
             required: false,
             default_value: 'desc',
             description: <<~EOS
               Sort order of sort by for KYC. Default is `DESC`.
             EOS

    def resolve(page: 1, page_size: 30, status: nil, sort: 'updated_at', sort_by: 'desc')
      source = Kyc
               .kept
               .select('*', "CONCAT(first_name, ' ', last_name) AS name")
               .order("#{sort} #{sort_by}")
               .preload(:user)

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
