module Mutations
  # Creates a new user account and returns a JWT token
  #
  # Example:
  #   mutation {
  #     signUp(email: "newuser@example.com", password: "securepassword") {
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
  class SignUp < BaseMutation
    description "Create a new user account and return JWT token"

    # Define input fields directly in the mutation
    argument :email, String, required: true, description: "User's email address (must be unique)"
    argument :password, String, required: true, description: "User's password (minimum length requirements may apply)"

    # Fields
    field :user, Types::UserType, null: true, description: "Newly created user object"
    field :token, String, null: true, description: "JWT token for subsequent authenticated requests"
    field :errors, [String], null: false, description: "Validation error messages if registration fails"

    def resolve(email:, password:)
      user = User.new(email: email, password: password)

      if user.save
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
          errors: user.errors.full_messages
        }
      end
    end
  end
end
