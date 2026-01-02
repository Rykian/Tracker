# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    description "A user in the system"

    field :id, ID, null: false
    field :email, String, null: true
    field :uploaded, GraphQL::Types::BigInt, null: false
    field :downloaded, GraphQL::Types::BigInt, null: false
    field :ratio, Float, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def email
      # Only return email if the current user is viewing their own profile
      return object.email if context[:current_user] == object
      nil
    end
  end
end
