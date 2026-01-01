require 'rails_helper'

RSpec.describe 'SignIn Mutation', type: :request do
  let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  let(:mutation) do
    <<~GQL
      mutation($email: String!, $password: String!) {
        signIn(email: $email, password: $password) {
          user {
            id
            email
          }
          token
          errors
        }
      }
    GQL
  end

  describe 'with valid credentials' do
    let(:variables) { { email: 'test@example.com', password: 'password123' } }

    it 'returns user and token' do
      post '/graphql', params: { query: mutation, variables: variables }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      data = json['data']['signIn']
      
      expect(data['user']['id']).to eq(user.id.to_s)
      expect(data['user']['email']).to be_nil # Email is private
      expect(data['token']).to be_present
      expect(data['errors']).to be_empty
    end
  end

  describe 'with invalid email' do
    let(:variables) { { email: 'wrong@example.com', password: 'password123' } }

    it 'returns authentication error' do
      post '/graphql', params: { query: mutation, variables: variables }
      
      json = JSON.parse(response.body)
      data = json['data']['signIn']
      
      expect(data['user']).to be_nil
      expect(data['token']).to be_nil
      expect(data['errors']).to include('Invalid email or password')
    end
  end

  describe 'with invalid password' do
    let(:variables) { { email: 'test@example.com', password: 'wrongpassword' } }

    it 'returns authentication error' do
      post '/graphql', params: { query: mutation, variables: variables }
      
      json = JSON.parse(response.body)
      data = json['data']['signIn']
      
      expect(data['user']).to be_nil
      expect(data['token']).to be_nil
      expect(data['errors']).to include('Invalid email or password')
    end
  end
end