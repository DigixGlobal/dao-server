# frozen_string_literal: true

require 'test_helper'

class CommentThreadTest < ActiveSupport::TestCase
  DEPTH_LIMITS = Rails.configuration.comments['depth_limits']

  test 'comment thread should work' do
    proposal = create(:proposal, comment: create(:comment, id: 0, stage: :archived))
    root_comment = proposal.comment

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

    threads = root_comment.user_stage_comments(
      proposal.user,
      nil,
      sort_by: :oldest
    )

    assert_equal [0, :archived,
                  [1, :archived,
                   [5, :archived,
                    [10, :archived,
                     :more],
                    :more],
                   [6, :archived,
                    [13, :archived]],
                   :more],
                  [2, :archived,
                   [14, :archived,
                    [15, :archived]]],
                  [3, :archived],
                  :more],
                 threads_to_view_dsl(root_comment, threads),
                 'thread should work'

    next_threads = root_comment.user_stage_comments(
      proposal.user,
      nil,
      sort_by: :oldest,
      last_seen_id: 2
    )

    assert_equal [0, :archived,
                  [3, :archived],
                  [4, :archived]],
                 threads_to_view_dsl(root_comment, next_threads),
                 'pagination should work'
  end

  test 'inserting in threads should work' do
    proposal = create(:proposal)
    root_comment = proposal.comment

    eval_build_dsl(
      root_comment,
      [
        nil,
        [
          :parent,
          [:parent],
          [:parent],
          [:parent],
          [:parent]
        ],
        [
          :parent
        ],
        [
          :parent
        ],
        [
          :parent
        ]
      ]
    )

    hack_comment_time

    threads = root_comment.user_stage_comments(
      proposal.user,
      nil,
      sort_by: :oldest
    )

    assert_equal (comment_views = comment_to_paginated_dsl(root_comment)),
                 (thread_views = threads_to_view_dsl(root_comment, threads)),
                 'thread should work'
  end

  private

  def hack_comment_time
    # Hack to force deterministic ordering with the created_at field
    Comment.in_batches.each do |relation|
      relation.update_all('created_at = FROM_UNIXTIME(id)')
    end
  end

  def filter_view_ids(views)
    views.flatten.select { |view| view.is_a?(Integer) }
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

  def comment_to_view_dsl(comment)
    [comment.id, comment.stage.to_sym].concat(
      comment.children.map { |child| comment_to_view_dsl(child) }
    )
  end

  def comment_to_paginated_dsl(comment, depth_limits = DEPTH_LIMITS, after_child_id: nil)
    return [comment.id, comment.stage.to_sym] if depth_limits.empty?

    limit, *rest_limits = depth_limits
    children = comment.children.to_a

    if after_child_id && (after_child_index = children.index { |child| child.id == after_child_id })
      children = children[(after_child_index + 1)..-1]
    end

    [comment.id, comment.stage.to_sym]
      .concat(
        children
          .take(limit)
          .map { |child| comment_to_paginated_dsl(child, rest_limits) }
      )
      .concat(children.size > limit ? [:more] : [])
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
