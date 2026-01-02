# frozen_string_literal: true

module Mutations
  # Authenticates a user and returns a JWT token
  #
  # Example:
  #   mutation {
  #     signIn(email: "user@example.com", password: "securepassword") {
  #       token
  #       user {
  #         id
  #         email
  #         uploaded
  #         downloaded
  #         ratio
  #       }
  #       errors
  #     }
  #   }
  #
  class SignIn < BaseMutation
    description "Sign in a user and return JWT token"

    # Arguments
    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true, description: "User's password"

    # Fields
    field :user, Types::UserType, null: true, description: "Authenticated user object"
    field :token, String, null: true, description: "JWT token for subsequent authenticated requests"
    field :errors, [String], null: false, description: "Error messages if authentication fails"

    def resolve(email:, password:)
      user = User.find_by(email: email)

      if user&.authenticate(password)
        token = JsonWebToken.encode(user_id: user.id)
        {
          user: user,
          token: token,
          errors: []
        }
      else
        {
          user: nil,
          token: nil,
          errors: ["Invalid email or password"]
        }
      end
    end
  end
end
