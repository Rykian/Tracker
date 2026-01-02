# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :current_user, Types::UserType, null: true,
      description: "Get current authenticated user"
    def current_user
      context[:current_user]
    end

    field :torrents, Types::TorrentType.connection_type, null: false do
      description "List of torrents"
      argument :category, Integer, required: false, description: "Filter by main category (includes subcategories)"
      argument :exact_category, Integer, required: false, description: "Filter by exact category ID"
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

    field :categories, [Types::CategoryType], null: false,
      description: "List all available torrent categories"
    def categories
      Category.all.map { |id, name| { id:, name: } }
    end
  end
end
