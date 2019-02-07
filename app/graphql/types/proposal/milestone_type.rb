# frozen_string_literal: true

module Types
  module Proposal
    class MilestoneType < Types::Base::BaseObject
      description 'Voting rounds for proposal voting'

      field :title, String,
            null: false,
            description: 'Title of the milestone'
      field :description, String,
            null: false,
            description: 'Description of the milestone'
    end
  end
end
