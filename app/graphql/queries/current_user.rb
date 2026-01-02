# frozen_string_literal: true

module Queries
  # Query the currently authenticated user
  #
  # Requires: Authorization header with valid JWT token
  #
  # Example:
  #   query {
  #     currentUser {
  #       id
  #       email
  #       uploaded
  #       downloaded
  #       ratio
  #       createdAt
  #       updatedAt
  #     }
  #   }
  #
  module CurrentUser
    def self.included(base)
      base.field :current_user, Types::UserType, null: true,
        description: "Get current authenticated user (requires JWT token in Authorization header)"
    end

    def current_user
      context[:current_user]
    end
  end
end
