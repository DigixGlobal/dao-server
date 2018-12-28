# frozen_string_literal: true

module Types
  class StageType < Types::BaseEnum
    value 'IDEA', 'To be endorsed by a moderator',
          value: 'idea'
    value 'DRAFT', 'To be voted on',
          value: 'draft'
    value 'ARCHIVED', 'Closed, finished or rejected',
          value: 'archived'
  end
end
