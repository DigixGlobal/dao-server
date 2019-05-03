# frozen_string_literal: true

require 'test_helper'

class SearchKycsQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($page: PositiveInteger, $pageSize: PositiveInteger, $status: KycStatusEnum, $sort: SearchKycFieldEnum, $sortBy: SortByEnum) {
      searchKycs(page: $page pageSize: $pageSize, status: $status, sort: $sort, sortBy: $sortBy) {
        edges {
          node {
            id
          }
        }
        hasNextPage
        hasPreviousPage
        totalPage
        totalCount
      }
    }
  EOS

  test 'search kycs should work' do
    officer = create(:kyc_officer_user)

    Kyc.statuses.keys.each do |status|
      create_list(:kyc, 5, status: status.to_sym)
      create(:kyc, status: status.to_sym, discarded_at: Time.now)
    end

    first_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(attributes_for(:search_kycs, page: 1, page_size: 3))
    )

    assert_nil first_result['errors'],
               'should work and have no errors'

    data = first_result['data']['searchKycs']

    assert data['hasNextPage'],
           'hasNextPage should work for the first page'
    refute data['hasPreviousPage'],
           'hasPreviousPage should work for the first page'
    assert_equal 2, data['totalPage'],
                 'totalPage should work'
    assert_equal 5, data['totalCount'],
                 'totalCount should work'

    last_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(attributes_for(:search_kycs, page: 2, page_size: 3))
    )

    assert_nil last_result['errors'],
               'should work'

    data = last_result['data']['searchKycs']

    refute data['hasNextPage'],
           'hasNextPage should work for the last page'
    assert data['hasPreviousPage'],
           'hasPreviousPage should work for the last page'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(attributes_for(:search_kycs, page: 3, page_size: 3))
    )

    assert_nil empty_result['errors'],
               'should work'

    data = empty_result['data']['searchKycs']

    refute data['hasNextPage'],
           'hasNextPage should work for empty pages'
    refute data['hasPreviousPage'],
           'hasPreviousPage should work for empty pages'
  end

  test 'search kycs should not display discarded entries work' do
    officer = create(:kyc_officer_user)

    Kyc.statuses.keys.each do |status|
      create_list(:kyc, 10, status: status.to_sym, discarded_at: Time.now)
    end

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(attributes_for(:search_kycs))
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['searchKycs']

    assert_empty data['edges'],
                 'should be empty'
  end

  test 'search kycs sorting options should work' do
    officer = create(:kyc_officer_user)

    Kyc.statuses.keys.each do |status|
      create_list(:kyc, 10, status: status.to_sym)
      Kyc.connection.execute('UPDATE `kycs` SET `updated_at` = FROM_DAYS(id), `created_at` = FROM_DAYS(id)')
    end

    status = generate(:kyc_status)
    sort = generate(:search_kyc_field)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(
        attributes_for(:search_kycs,
                       status: status,
                       sort: sort,
                       sort_by: 'ASC',
                       page: 1,
                       page_size: 10)
      )
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['searchKycs']['edges'].map { |edge| edge['node'] }

    assert_not_empty data,
                     'should not be empty'

    reverse_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: officer },
      variables: normalize_variables(
        attributes_for(:search_kycs,
                       status: status,
                       sort: sort,
                       sort_by: 'DESC',
                       page: 1,
                       page_size: 10)
      )
    )

    reverse_data = reverse_result['data']['searchKycs']['edges'].map { |edge| edge['node'] }

    assert_equal data.map { |kyc| kyc['id'] }, reverse_data.map { |kyc| kyc['id'] }.reverse,
                 'sorting should work'
  end

  test 'should fail safely' do
    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: {}
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a regular user'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end

  private

  def normalize_variables(vars)
    vars[:status] = vars[:status]&.upcase

    vars.to_h.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end
end
