module Mutations
  class SignUp < BaseMutation
    description "Create a new user account"

    # Define input fields directly in the mutation
    argument :email, String, required: true
    argument :password, String, required: true

    # Fields
    field :user, Types::UserType, null: true
    field :token, String, null: true
    field :errors, [String], null: false

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