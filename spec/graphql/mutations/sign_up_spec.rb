require 'rails_helper'

RSpec.describe 'SignUp Mutation', type: :request do
  let(:mutation) do
    <<~GQL
      mutation($email: String!, $password: String!) {
        signUp(email: $email, password: $password) {
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

  describe 'with valid parameters' do
    let(:variables) { { email: 'test@example.com', password: 'password123' } }

    it 'creates a new user' do
      expect {
        post '/graphql', params: { query: mutation, variables: variables }
      }.to change(User, :count).by(1)
    end

    it 'returns user data and token' do
      post '/graphql', params: { query: mutation, variables: variables }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      data = json['data']['signUp']

      expect(data['user']['id']).to be_present
      expect(data['user']['email']).to be_nil # Email is private
      expect(data['token']).to be_present
      expect(data['errors']).to be_empty
    end
  end

  describe 'with invalid parameters' do
    let(:variables) { { email: 'invalid-email', password: '123' } }

    it 'does not create a user' do
      expect {
        post '/graphql', params: { query: mutation, variables: variables }
      }.not_to change(User, :count)
    end

    it 'returns errors' do
      post '/graphql', params: { query: mutation, variables: variables }

      json = JSON.parse(response.body)
      data = json['data']['signUp']

      expect(data['user']).to be_nil
      expect(data['token']).to be_nil
      expect(data['errors']).to include('Email is invalid')
      expect(data['errors']).to include('Password is too short (minimum is 6 characters)')
    end
  end

  describe 'with duplicate email' do
    let!(:existing_user) { create(:user, email: 'test@example.com') }
    let(:variables) { { email: 'test@example.com', password: 'password123' } }

    it 'returns email taken error' do
      post '/graphql', params: { query: mutation, variables: variables }

      json = JSON.parse(response.body)
      data = json['data']['signUp']

      expect(data['errors']).to include('Email has already been taken')
    end
  end
end
