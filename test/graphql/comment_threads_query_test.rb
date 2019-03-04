# frozen_string_literal: true

require 'test_helper'

class CommentThreadsQueryTest < ActionDispatch::IntegrationTest
  QUERY = <<~EOS
    query($proposalId: String, $commentId: String, $stage: ProposalStageEnum, $after: String, $sortBy: ThreadSortByEnum) {
      commentThreads(first: 3, proposalId: $proposalId, commentId: $commentId, after: $after, stage: $stage, sortBy: $sortBy) {
        edges {
           node {
             id
             stage
             body
             likes
             liked
             createdAt
             parentId
             user {
               address
               displayName
             }
             replies(first: 2) {
               edges {
                 node {
                   id
                   stage
                   body
                   likes
                   liked
                   createdAt
                   parentId
                   user {
                     address
                     displayName
                   }
                   replies(first: 1) {
                     edges {
                       node {
                         id
                         stage
                         body
                         likes
                         liked
                         createdAt
                         parentId
                         user {
                           address
                           displayName
                         }
                         replies(first: 0) {
                           hasNextPage
                           endCursor
                         }
                      }
                    }
                    hasNextPage
                    endCursor
                  }
                }
              }
              hasNextPage
              endCursor
            }
          }
        }
        hasNextPage
        endCursor
      }
    }
  EOS

  AUTHORIZED_QUERY = <<~EOS
    query($proposalId: String, $commentId: String, $stage: ProposalStageEnum, $after: String) {
      commentThreads(first: 10, proposalId: $proposalId, commentId: $commentId, after: $after, stage: $stage) {
        edges {
           node {
             id
             isBanned
           }
        }
      }
    }
  EOS

  test 'comment threads query should work' do
    user = create(:user)
    proposal = FactoryBot.create(:proposal_with_comments)

    proposal_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        proposal_id: proposal.proposal_id
      )
    )

    assert_nil proposal_result['errors'],
               'should work with proposal id and have no errors'
    assert_not_empty proposal_result['data']['commentThreads']['edges'],
                     'should have data'

    comment = proposal.comment.children.sample

    comment_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        comment_id: comment.id.to_s,
        stage: comment.stage
      )
    )

    assert_nil comment_result['errors'],
               'should work with comment id and have no errors'
  end

  test 'fields should work' do
    user = create(:user)
    proposal = FactoryBot.create(:proposal_with_comments)

    proposal.comment.children.each do |comment|
      Comment.like(user, comment)
    end

    liked_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        proposal_id: proposal.proposal_id
      )
    )

    comments = liked_result['data']['commentThreads']['edges']
               .map { |edge| edge['node'] }

    comments.each do |comment|
      assert comment['liked'],
             'liked field should work'
      assert_equal 1, comment['likes'],
                   'likes field should work'
    end

    comments.flat_map { |comment| comment['replies']['edges'] }
            .map { |edge| edge['node'] }
            .each do |reply|
              refute reply['liked'],
                     'liked field should work'
              assert_equal 0, reply['likes'],
                           'likes field should work'
            end

    unauthorized_result = DaoServerSchema.execute(
      AUTHORIZED_QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        proposal_id: proposal.proposal_id
      )
    )

    assert_not_empty unauthorized_result['errors'],
                     '`isBanned` should not exist'

    authorized_result = DaoServerSchema.execute(
      AUTHORIZED_QUERY,
      context: { current_user: create(:forum_admin_user) },
      variables: normalize_attributes(
        proposal_id: proposal.proposal_id
      )
    )

    assert_nil authorized_result['errors'],
               '`isBanned` should exist'
  end

  test 'should fail safely' do
    user = create(:user)

    invalid_proposal_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        proposal_id: 'NON_EXISTENT_ID'
      )
    )

    assert_not_empty invalid_proposal_result['errors'],
                     'should fail if proposal id does not exist'

    invalid_comment_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(
        comment_id: 'NON_EXISTENT_ID'
      )
    )

    assert_not_empty invalid_comment_result['errors'],
                     'should fail if comment id does not exist'

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes({})
    )

    assert_not_empty empty_result['errors'],
                     'should fail with empty data'
  end

  test 'should match old data' do
    user = create(:user)
    proposal = FactoryBot.create(:proposal)

    eval_build_dsl(
      proposal.comment,
      [nil,
       [1, :parent,
        [5, :parent,
         [8, :parent,
          [11, :parent,
           [12, :parent]]],
         [9, :parent]],
        [6, :parent,
         [10, :parent]],
        [7, :parent]],
       [2, :parent,
        [13, :parent,
         [15, :parent]],
        [14, :parent,
         [16, :parent]]],
       [3, :parent],
       [4, :parent]]
    )

    params = {
      proposal_id: proposal.proposal_id,
      stage: proposal.stage,
      sort_by: :oldest
    }

    new_data = query_result(user, params)
    old_data = controller_result(user, params)

    assert_equal old_data, new_data,
                 'should be the same with proposals'

    proposal.comment.descendants.each do |comment|
      params = {
        comment_id: comment.id,
        stage: comment.stage,
        sort_by: :oldest
      }

      new_data = query_result(user, params)
      old_data = controller_result(user, params)

      assert_equal old_data, new_data,
                   'should be the same with comments'
    end

    proposal.comment.children.each do |comment|
      params = {
        proposal_id: proposal.proposal_id,
        stage: proposal.stage,
        sort_by: :oldest,
        last_seen_id: comment.id
      }

      new_data = query_result(user, params)
      old_data = controller_result(user, params)

      assert_equal old_data, new_data,
                   'should be the same with after option'

      new_params = params.merge(sort_by: :oldest)

      new_reverse_data = query_result(user, new_params)
      old_reverse_data = controller_result(user, new_params)

      assert_equal old_reverse_data, new_reverse_data,
                   'should be the same with after option'
    end

    %i[oldest latest].each do |sort_by|
      params = {
        comment_id: proposal.comment.id,
        stage: proposal.stage,
        sort_by: sort_by
      }

      raw_data = query_result(user, params, raw: true)

      next if raw_data['edges'].empty?

      after_params = params.merge(
        last_seen_id: raw_data['edges'].last['node']['id'].to_i,
        after: raw_data['endCursor']
      )

      new_after_data = query_result(user, after_params)
      old_after_data = controller_result(user, after_params)

      assert_equal old_after_data, new_after_data,
                   'cursor should be working'
    end

    params = {
      proposal_id: proposal.proposal_id,
      stage: proposal.stage,
      sort_by: :oldest
    }

    new_data = query_result(user, params, raw: true)

    first_level_comment =  new_data['edges'][0]['node']
    second_level_comment = first_level_comment['replies']['edges'][0]['node']
    third_level_comment = second_level_comment['replies']['edges'][0]['node']

    leaf_params = {
      proposal_id: proposal.proposal_id,
      stage: proposal.stage,
      sort_by: :oldest,
      after: third_level_comment['replies']['endCursor']
    }

    leaf_data = query_result(user, leaf_params)

    assert_equal [false, [0, '11', [false, [1, '12', [false]]]]], leaf_data,
                 'leaf cursor should be working'
  end

  private

  def normalize_attributes(attrs)
    attrs[:comment_id] = attrs[:comment_id].to_s if attrs[:comment_id].present?
    attrs[:stage] = attrs[:stage].to_s.upcase if attrs[:stage].present?
    attrs[:sort_by] = attrs[:sort_by].to_s.upcase if attrs[:sort_by].present?

    if !attrs[:after].present? && attrs[:last_seen_id].present?
      comment = Comment.find(attrs[:last_seen_id])

      attrs[:after] = Base64.strict_encode64({ parent_id: comment.parent_id, date_after: comment.created_at.iso8601 }.to_json)
    end

    attrs.to_h.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end

  def query_result(user, attrs, raw: false)
    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: normalize_attributes(**attrs)
    )

    data = result['data']['commentThreads'].to_h

    raw ? data : replies_to_threads(data)
  end

  def controller_result(user, attrs)
    comment_id =
      if (proposal_id = attrs.fetch(:proposal_id, nil))
        Proposal.find_by(proposal_id: proposal_id).comment_id
      else
        attrs.fetch(:comment_id, nil)
      end

    get comment_threads_path(comment_id),
        params: attrs,
        headers: user.create_new_auth_token

    result = JSON.parse(@response.body)

    response_to_threads(result['result'])
  end

  def replies_to_threads(replies, depth = 0)
    has_more = replies.dig('hasNextPage')

    return [has_more] if replies['edges']&.empty?

    inner_replies = replies['edges']&.map { |edge| edge['node'] } || []

    data = inner_replies.map do |reply|
      [depth, reply['id'], replies_to_threads(reply['replies'], depth + 1)]
    end

    [has_more, *data]
  end

  def response_to_threads(threads, depth = 0)
    has_more = threads['hasMore']

    comments = threads['data'].map do |comment|
      [depth, comment['id'].to_s, response_to_threads(comment['replies'], depth + 1)]
    end

    [has_more, *comments]
  end

  def eval_build_dsl(parent_comment, dsl)
    return [] if dsl.empty?

    id, stage, child_dsls =
      if dsl.first.is_a?(Integer)
        [dsl[0], dsl[1], dsl.slice(2..-1)]
      else
        [nil, dsl[0], dsl.slice(1..-1)]
      end

    stage = parent_comment.stage if (stage == :parent) && parent_comment

    comment =
      if stage.nil?
        parent_comment
      else
        create(:comment,
               id: id,
               stage: stage,
               parent: parent_comment,
               created_at: Time.now + id.minutes)
      end

    children = (child_dsls || [])
               .reject { |child_dsl| child_dsl == :more }
               .map { |child_dsl| eval_build_dsl(comment, child_dsl) }

    [comment.slice(:id, :stage, :parent_id).to_h].concat(children)
  end
end
