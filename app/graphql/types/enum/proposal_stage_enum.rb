# frozen_string_literal: true

module Types
  module Enum
    class ProposalStageEnum < Types::Base::BaseEnum
      description 'Phases or stages for a proposal or comment'

      value 'IDEA', 'To be endorsed by a moderator',
            value: 'idea'
      value 'DRAFT', 'To be voted on',
            value: 'draft'
      value 'ARCHIVED', 'Closed, finished or rejected',
            value: 'archived'
    end
  end
end
