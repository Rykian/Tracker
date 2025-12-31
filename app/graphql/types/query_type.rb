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

    field :torrents, [Types::TorrentType], null: false,
      description: "Get all torrents" do
      argument :category, String, required: false, description: "Filter by category"
      argument :limit, Integer, required: false, description: "Limit number of results"
      argument :offset, Integer, required: false, description: "Offset for pagination"
    end
    def torrents(category: nil, limit: nil, offset: nil)
      query = Torrent.includes(:user)
      query = query.where(category: category) if category.present?
      query = query.offset(offset) if offset.present?
      query = query.limit(limit) if limit.present?
      query.order(created_at: :desc)
    end
  end
end
