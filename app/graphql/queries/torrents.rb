# frozen_string_literal: true

module Queries
  # Query torrents with optional category filtering
  #
  # Example:
  #   query {
  #     torrents(first: 10, category: 1) {
  #       edges {
  #         node {
  #           id
  #           name
  #           infoHash
  #           size
  #           seeders
  #           leechers
  #           completed
  #           magnetLink
  #           category { id name }
  #           createdAt
  #         }
  #       }
  #     }
  #   }
  #
  module Torrents
    def self.included(base)
      base.field :torrents, Types::TorrentType.connection_type, null: false do
        description "List torrents with optional category filtering and pagination support"
        argument :category, Integer, required: false, description: "Filter by main category (includes subcategories)"
        argument :exact_category, Integer, required: false, description: "Filter by exact category ID"
      end
    end

    def torrents(category: nil, exact_category: nil)
      torrents = Torrent.includes(:user)

      if exact_category
        torrents = torrents.where(category_id: exact_category)
      elsif category
        torrents = torrents.where(category_id: Category.family_ids_for(category))
      end

      torrents.order(created_at: :desc)
    end
  end
end
