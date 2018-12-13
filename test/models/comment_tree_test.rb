# frozen_string_literal: true

require 'test_helper'

class CommentThreadTest < ActiveSupport::TestCase
  DEPTH_LIMITS = Rails.configuration.comments['depth_limits']

  test 'comment thread should work' do
    proposal = create(:proposal)
    root_comment = proposal.comment

    base_id = Random.rand(1_000_000)

    ids = eval_build_dsl(
      root_comment,
      [
        nil,
        [
          (first_id = base_id + 1),
          :parent,
          [
            :parent,
            [:parent],
            [:parent]
          ],
          [
            (child_id = base_id + 5),
            :parent,
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
        ],
        [
          (second_id = base_id + 2),
          :parent,
          [
            :parent,
            [:parent]
          ]
        ],
        [
          (top_id = base_id + 3),
          :parent
        ],
        [
          (next_top_id = base_id + 4),
          :parent
        ]
      ]
    )
          .flatten
          .map { |item| item.fetch('id') }

    assert_equal 15, Comment.count,
                 'comments should be created'

    hack_comment_time

    threads = root_comment.user_stage_comments(
      proposal.user,
      nil,
      sort_by: :oldest
    )

    assert_equal (comment_views = comment_to_paginated_dsl(root_comment)),
                 (thread_views = threads_to_view_dsl(root_comment, threads)),
                 'thread should work'

    puts comment_views.inspect
    puts thread_views.inspect

    next_threads = root_comment.user_stage_comments(
      proposal.user,
      nil,
      sort_by: :oldest,
      last_seen_id: top_id
    )

    puts next_threads.inspect

    puts next_top_id
    puts threads_to_view_dsl(root_comment, threads).inspect
    puts threads_to_view_dsl(root_comment, next_threads).inspect
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

  def comment_to_paginated_dsl(comment, depth_limits = DEPTH_LIMITS)
    return [comment.id, comment.stage.to_sym] if depth_limits.empty?

    limit, *rest_limits = depth_limits
    children = comment.children.to_a

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
