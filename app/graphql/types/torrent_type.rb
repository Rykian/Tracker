# frozen_string_literal: true

module Types
  class TorrentType < Types::BaseObject
    description "A torrent in the system"

    field :id, ID, null: false
    field :info_hash, String, null: false
    field :name, String, null: false
    field :size, GraphQL::Types::BigInt, null: false
    field :piece_length, Integer, null: true
    field :num_pieces, Integer, null: true
    field :files, [GraphQL::Types::JSON], null: false
    field :description, String, null: true
    field :category, Types::CategoryType, null: true, description: "Category object with ID and name"
    field :private, Boolean, null: false
    field :created_by, String, null: true
    field :announce_urls, String, null: true
    field :seeders, Integer, null: false
    field :leechers, Integer, null: false
    field :completed, Integer, null: false
    field :user, Types::UserType, null: false
    field :magnet_link, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def category
      return nil unless object.category_id.present?
      { id: object.category_id, name: object.category_name }
    end
  end
end
