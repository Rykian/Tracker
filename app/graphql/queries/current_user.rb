# frozen_string_literal: true

module Queries
  module CurrentUser
    def self.included(base)
      base.field :current_user, Types::UserType, null: true,
        description: "Get current authenticated user"
    end

    def current_user
      context[:current_user]
    end
  end
end
