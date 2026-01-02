# frozen_string_literal: true

module Queries
  module Categories
    def self.included(base)
      base.field :categories, [Types::CategoryType], null: false,
        description: "List all available torrent categories"
    end

    def categories
      Category.all.map { |id, name| { id:, name: } }
    end
  end
end
