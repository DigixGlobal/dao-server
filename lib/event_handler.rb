# frozen_string_literal: true

class EventHandler
  EVENT_TYPES = {
    project_created: 'EVENT_PROJECT_CREATED',
    project_endorsed: 'EVENT_PROJECT_ENDORSED',
    project_prl_paused: 'EVENT_PROJECT_PRL_PAUSED',
    project_prl_stopped: 'EVENT_PROJECT_PRL_STOPPED'
  }.freeze

  class << self
    def handle_event(attrs)
      type = attrs.fetch(:event_type, nil)

      unless (event_type = EVENT_TYPES.invert.fetch(type, nil))
        return [:invalid_event_type, nil]
      end

      proposal_id = attrs.fetch(:proposal_id, nil)

      unless (proposal = Proposal.find_by(proposal_id: proposal_id))
        return [:proposal_not_found, nil]
      end

      case event_type
      when :project_created
        NotificationMailer.with(proposal: proposal)
                          .project_created.deliver_now
      when :project_endorsed
        NotificationMailer.with(proposal: proposal)
                          .project_endorsed.deliver_now
      when :project_prl_paused
        NotificationMailer.with(proposal: proposal)
                          .project_prl_paused.deliver_now
      when :project_prl_stopped
        NotificationMailer.with(proposal: proposal)
                          .project_prl_stopped.deliver_now
      end

      [:ok, nil]
    end
  end
end
