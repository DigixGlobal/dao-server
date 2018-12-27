# frozen_string_literal: true

require 'test_helper'

class CommentThreadTest < ActiveSupport::TestCase
  DEPTH_LIMITS = Rails.configuration.comments['depth_limits']

  test 'comment thread should work' do
    root_comment = create_root_comment
    stage = root_comment.stage.to_sym

    eval_build_dsl(
      root_comment,
      [nil,
       [1, :parent,
        [5, :parent,
         [10, :parent,
          [12, :parent]],
         [11, :parent]],
        [6, :parent,
         [13, :parent]],
        [7, :parent],
        [8, :parent],
        [9, :parent]],
       [2, :parent,
        [14, :parent,
         [15, :parent]]],
       [3, :parent],
       [4, :parent]]
    )

    assert_equal 16, Comment.count,
                 'comments should be created'

    hack_comment_time

    assert_equal [0, stage,
                  [1, stage,
                   [5, stage,
                    [10, stage,
                     :more],
                    :more],
                   [6, stage,
                    [13, stage]],
                   :more],
                  [2, stage,
                   [14, stage,
                    [15, stage]]],
                  [3, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     nil,
                     sort_by: :oldest
                   )
                 ),
                 'thread view should work'
  end

  test 'inserting new comments should work' do
    root_comment = create_root_comment
    stage = root_comment.stage.to_sym

    eval_build_dsl(
      root_comment,
      [nil,
       [1, :parent,
        [3, :parent]],
       [2, :parent]]
    )

    _ok, new_comment = Comment.comment(
      root_comment.user,
      root_comment,
      attributes_for(:comment)
    )

    hack_comment_time

    assert_equal [0, stage,
                  [1, stage,
                   [3, stage]],
                  [2, stage],
                  [new_comment.id, stage]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     nil,
                     sort_by: :oldest
                   )
                 ),
                 'new comments should be at the end'

    _ok, newer_comment = Comment.comment(
      root_comment.user,
      root_comment,
      attributes_for(:comment)
    )

    hack_comment_time

    assert_equal [0, stage,
                  [1, stage,
                   [3, stage]],
                  [2, stage],
                  [new_comment.id, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     nil,
                     sort_by: :oldest
                   )
                 ),
                 'newer comments should be requested instead'
  end

  test 'comments should be separated by stage' do
    root_comment = create_root_comment
    stage = root_comment.stage.to_sym

    eval_build_dsl(
      root_comment,
      [nil,
       [1, :idea,
        [2, :draft],
        [3, :archived]],
       [4, :draft,
        [5, :idea],
        [6, :archived]],
       [7, :archived,
        [8, :idea],
        [9, :draft]],
       [10, :idea,
        [11, :idea],
        [12, :draft]],
       [13, :draft,
        [14, :draft,
         [15, :draft],
         [16, :archived]],
        [17, :archived]],
       [18, :archived,
        [19, :archived,
         [20, :archived,
          [21, :archived]],
         [22, :archived]],
        [23, :archived],
        [24, :archived]]]
    )

    hack_comment_time

    assert_equal [0, stage,
                  [1, :idea],
                  [10, :idea,
                   [11, :idea]]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     :idea,
                     sort_by: :oldest
                   )
                 ),
                 'idea filter should work'

    assert_equal [0, stage,
                  [4, :draft],
                  [13, :draft,
                   [14, :draft,
                    [15, :draft]]]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     :draft,
                     sort_by: :oldest
                   )
                 ),
                 'draft filter and nesting should work'

    assert_equal [0, stage,
                  [7, :archived],
                  [18, :archived,
                   [19, :archived,
                    [20, :archived,
                     :more],
                    :more],
                   [23, :archived],
                   :more]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     :archived,
                     sort_by: :oldest
                   )
                 ),
                 'archived filter and pagination should work'
  end

  test 'thread pagination should work' do
    root_comment = create_root_comment
    stage = root_comment.stage.to_sym

    eval_build_dsl(
      root_comment,
      [nil,
       [1, :parent,
        [8, :parent,
         [12, :parent,
          [14, :parent],
          [15, :parent]],
         [13, :parent]],
        [9, :parent],
        [10, :parent],
        [11, :parent]],
       [2, :parent],
       [3, :parent],
       [4, :parent],
       [5, :parent],
       [6, :parent],
       [7, :parent]]
    )

    hack_comment_time

    assert_equal [0, stage,
                  [1, stage,
                   [8, stage,
                    [12, stage,
                     :more],
                    :more],
                   [9, stage],
                   :more],
                  [2, stage],
                  [3, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :oldest
                   )
                 ),
                 'initial pagination should work'

    assert_equal [0, stage,
                  [4, stage],
                  [5, stage],
                  [6, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :oldest,
                     last_seen_id: 3
                   )
                 ),
                 'next set of data should be fetched'

    assert_equal [0, stage,
                  [7, stage]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :oldest,
                     last_seen_id: 6
                   )
                 ),
                 'last page of data should be fetched'

    child_comment = Comment.find(1)

    assert_equal [1, stage,
                  [8, stage,
                   [12, stage,
                    [14, stage],
                    :more],
                   [13, stage]],
                  [9, stage],
                  [10, stage],
                  :more],
                 threads_to_view_dsl(
                   child_comment,
                   child_comment.user_stage_comments(
                     child_comment.user,
                     stage,
                     sort_by: :oldest
                   )
                 ),
                 'pagination should work for children'
  end

  test 'thread sorting should work' do
    root_comment = create_root_comment
    stage = root_comment.stage.to_sym

    eval_build_dsl(
      root_comment,
      [nil,
       [1, :parent,
        [5, :parent],
        [6, :parent],
        [7, :parent],
        [8, :parent]],
       [2, :parent],
       [3, :parent],
       [4, :parent]]
    )

    hack_comment_time

    assert_equal [0, stage,
                  [1, stage,
                   [5, stage],
                   [6, stage],
                   :more],
                  [2, stage],
                  [3, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :oldest
                   )
                 ),
                 'sorting by oldest should work'

    assert_equal [0, stage,
                  [4, stage],
                  [3, stage],
                  [2, stage],
                  :more],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :latest
                   )
                 ),
                 'sorting by latest should work'

    assert_equal [0, stage,
                  [1, stage,
                   [5, stage],
                   [6, stage],
                   :more]],
                 threads_to_view_dsl(
                   root_comment,
                   root_comment.user_stage_comments(
                     root_comment.user,
                     stage,
                     sort_by: :latest,
                     last_seen_id: 2
                   )
                 ),
                 'parent sorting should not affect children'

    child_comment = Comment.find(1)

    assert_equal [1, stage,
                  [5, stage],
                  [6, stage],
                  [7, stage],
                  :more],
                 threads_to_view_dsl(
                   child_comment,
                   child_comment.user_stage_comments(
                     child_comment.user,
                     stage,
                     sort_by: :latest
                   )
                 ),
                 'sorting option should not work with child comment'
  end

  test 'thread view should work' do
    root_comment = create_root_comment
    stage = root_comment.stage
    user = create(:user)

    ok, comment = Comment.comment(user, root_comment, body: 'ONLY_COMMENT')

    assert_equal :ok, ok,
                 'should insert comment'

    result = root_comment
             .user_stage_comments(
               user,
               stage,
               {}
             )
             .as_json({})

    assert_not result.dig('data', 0, 'liked'),
               'should not be liked'

    ok, _liked_comment = Comment.like(user, comment)

    assert_equal :ok, ok,
                 'should like comment'

    liked_result = root_comment
                   .user_stage_comments(
                     user,
                     stage,
                     {}
                   )
                   .as_json({})

    assert liked_result.dig('data', 0, 'liked'),
           'should now be liked'

    other_user = create(:user)

    unliked_result = root_comment
                     .user_stage_comments(
                       other_user,
                       stage,
                       {}
                     )
                     .as_json({})

    assert_not unliked_result.dig('data', 0, 'liked'),
               'should not be liked with the other user'
  end

  private

  def hack_comment_time
    # Hack to force deterministic ordering with the created_at field
    sleep(2.second)
    Comment.in_batches.each do |relation|
      relation.update_all('created_at = FROM_UNIXTIME(id)')
    end
  end

  def create_root_comment(**kwargs)
    stage = generate(:proposal_stage).to_sym
    proposal = create(
      :proposal,
      stage: stage,
      comment: create(:comment, id: 0, stage: stage, **kwargs)
    )

    proposal.comment
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
        create(:comment, id: id, stage: stage, parent: parent_comment)
      end

    children = (child_dsls || [])
               .reject { |child_dsl| child_dsl == :more }
               .map { |child_dsl| eval_build_dsl(comment, child_dsl) }

    [comment.slice(:id, :stage, :parent_id).to_h].concat(children)
  end

  def threads_to_view_dsl(parent_comment, data)
    if data.is_a?(Comment::DataWrapper)
      wrapper = data

      id, stage =
        if parent_comment.nil?
          [nil, nil]
        else
          [parent_comment.id, parent_comment.stage.to_sym]
        end

      replies = wrapper
                .data
                .map { |reply| threads_to_view_dsl(parent_comment, reply) }

      [id, stage]
        .concat(replies)
        .concat(data.has_more ? [:more] : [])
    elsif data.is_a?(Array)
      return [] if threads.empty?

      data.map { |thread| threads_to_view_dsl(parent_comment, thread) }
    elsif data.is_a?(Comment)
      threads_to_view_dsl(data, data.replies)
    end
  end
end
