# frozen_string_literal: true

module Types
  class SortByType < Types::BaseEnum
    value 'DESC', 'Sort in descending creation time',
          value: 'desc'
    value 'ASC', 'Sort in ascending creation time',
          value: 'asc'
  end
end
