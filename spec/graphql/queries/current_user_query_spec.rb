require 'rails_helper'

RSpec.describe 'CurrentUser Query', type: :request do
  describe 'currentUser query' do
    let(:query) do
      <<~GQL
        query {
          currentUser {
            id
            email
            createdAt
            updatedAt
          }
        }
      GQL
    end

    context 'when user is authenticated' do
      let!(:user) { create(:user) }
      let(:token) { JsonWebToken.encode(user_id: user.id) }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      it 'returns current user data' do
        post '/graphql', params: { query: query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json['data']['currentUser']
        
        expect(data['id']).to eq(user.id.to_s)
        expect(data['email']).to eq(user.email)
        expect(data['createdAt']).to be_present
        expect(data['updatedAt']).to be_present
      end
    end

    context 'when user is not authenticated' do
      it 'returns null for current user' do
        post '/graphql', params: { query: query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['currentUser']).to be_nil
      end
    end

    context 'with invalid token' do
      let(:headers) { { 'Authorization' => 'Bearer invalid-token' } }

      it 'returns null for current user' do
        post '/graphql', params: { query: query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['currentUser']).to be_nil
      end
    end

    context 'with expired token' do
      let!(:user) { create(:user) }
      let(:expired_token) { JsonWebToken.encode({ user_id: user.id }, 1.hour.ago) }
      let(:headers) { { 'Authorization' => "Bearer #{expired_token}" } }

      it 'returns null for current user' do
        post '/graphql', params: { query: query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['currentUser']).to be_nil
      end
    end
  end

  describe 'currentUser query without authentication' do
    let(:query) do
      <<~GQL
        query {
          currentUser {
            id
            email
          }
        }
      GQL
    end

    it 'returns null when not authenticated' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['data']['currentUser']).to be_nil
    end
  end

  describe 'user email privacy' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'viewing own user' do
      let(:query) do
        <<~GQL
          query {
            currentUser {
              id
              email
            }
          }
        GQL
      end

      it 'returns own email' do
        post '/graphql', params: { query: query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['currentUser']['email']).to eq(user.email)
      end
    end

    context 'viewing other user via torrent owner' do
      let!(:torrent) { create(:torrent, user: other_user) }
      let(:query) do
        <<~GQL
          query {
            torrents {
              edges {
                node {
                  user {
                    id
                    email
                  }
                }
              }
            }
          }
        GQL
      end

      it 'returns nil for other users email' do
        post '/graphql', params: { query: query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json['data']['torrents']['edges'].map { |edge| edge['node'] }
        
        expect(data[0]['user']['id']).to eq(other_user.id.to_s)
        expect(data[0]['user']['email']).to be_nil
      end
    end
  end
end
