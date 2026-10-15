# frozen_string_literal: true

class CommentNotificationJob < ActiveJob::Base
  queue_as :mailers

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(comment_id, proposal_id)
    comment = Comment.find_by(id: comment_id)
    proposal = Proposal.includes(:user).find_by(id: proposal_id)
    return unless comment && proposal
    return if comment.discarded? || comment.user_id == proposal.user_id
    return if proposal.user.email.blank?

    title = proposal_title(proposal)

    NotificationMailer
      .with(proposal: proposal, proposal_title: title, comment: comment)
      .project_comment
      .deliver_now
  end

  private

  def proposal_title(proposal)
    result, records = InfoApi.list_proposals
    return proposal.proposal_id unless result == :ok

    record = records.find { |item| item['proposal_id'] == proposal.proposal_id }
    record && record['title'].present? ? record['title'] : proposal.proposal_id
  rescue StandardError => error
    Rails.logger.info("Unable to load proposal title for comment notification (#{error.class})")
    proposal.proposal_id
  end
end
