# frozen_string_literal: true

require 'info_api'

module Types
  module Proposal
    class LazyPoints
      def initialize(query_ctx, object, key)
        @user = object
        @key = key

        @lazy_state = query_ctx[:lazy_points] ||= {
          pending_ids: Set.new,
          loaded_ids: {}
        }

        @lazy_state[:pending_ids] << @user.address
      end

      def points
        address = @user.address
        loaded_record = @lazy_state[:loaded_ids][address]

        if loaded_record
          @lazy_state[:pending_ids].delete(address)

          loaded_record[@key]
        else
          addresses = @lazy_state[:pending_ids].to_a

          result, points_or_error = InfoApi.fetch_points(addresses)

          raise GraphQL::ExecutionError, 'Network failure' unless result == :ok

          addresses.each do |this_address|
            point = if points_or_error.key?(this_address)
                      {
                        quarter_point: points_or_error.dig(this_address, 'quarter_points') || '0',
                        reputation_point: points_or_error.dig(this_address, 'reputation') || '0'
                      }
                    else
                      {
                        quarter_point: '0',
                        reputation_point: '0'
                      }
                    end

            @lazy_state[:loaded_ids][this_address] = point
          end

          @lazy_state[:pending_ids].clear

          @lazy_state[:loaded_ids][address][@key]
        end
      end
    end
  end
end
