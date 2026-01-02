# frozen_string_literal: true

module Types
  class CategoryType < Types::BaseObject
    description "A torrent category from Torznab specification"

    field :id, Integer, null: false, description: "Torznab category ID"
    field :name, String, null: false, description: "Category name"
  end
end
