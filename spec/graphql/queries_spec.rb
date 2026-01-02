require 'rails_helper'

RSpec.describe 'GraphQL Queries', type: :request do
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

  describe 'torrents query' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:torrents) { create_list(:torrent, 3, user: user) }
    let!(:other_torrents) { create_list(:torrent, 2, user: other_user) }

    let(:query) do
      <<~GQL
        query {
          torrents {
            edges {
              node {
                id
                name
                size
                infoHash
                seeders
                leechers
                completed
                category
                magnetLink
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

    it 'returns all torrents' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      edges = json['data']['torrents']['edges']
      data = edges.map { |edge| edge['node'] }
      
      expect(data.length).to eq(5)
      expect(data[0]['name']).to be_present
      expect(data[0]['infoHash']).to be_present
      expect(data[0]['magnetLink']).to include('magnet:')
    end

    context 'with category filter' do
      before do
        torrents.each { |t| t.update(category: 'TV') }
        other_torrents.each { |t| t.update(category: 'Software') }
      end

      let(:filtered_query) do
        <<~GQL
          query {
            torrents(category: "TV") {
              edges {
                node {
                  id
                  category
                }
              }
            }
          }
        GQL
      end

      it 'filters torrents by category' do
        post '/graphql', params: { query: filtered_query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        edges = json['data']['torrents']['edges']
        data = edges.map { |edge| edge['node'] }
        
        expect(data.length).to eq(3)
        expect(data.all? { |t| t['category'] == 'TV' }).to be true
      end
    end

    context 'with pagination' do
      let(:paginated_query) do
        <<~GQL
          query {
            torrents(first: 2) {
              edges {
                node {
                  id
                  name
                }
              }
            }
          }
        GQL
      end

      it 'limits and offsets results' do
        post '/graphql', params: { query: paginated_query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        edges = json['data']['torrents']['edges']
        data = edges.map { |edge| edge['node'] }
        
        expect(data.length).to eq(2)
      end
    end

    context 'email privacy - unauthenticated user' do
      it 'does not return torrent creator email for unauthenticated users' do
        post '/graphql', params: { query: query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json['data']['torrents']['edges'].map { |edge| edge['node'] }
        
        expect(data[0]['user']['email']).to be_nil
      end
    end

    context 'email privacy - viewing own torrents' do
      let(:token) { JsonWebToken.encode(user_id: user.id) }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      let(:own_torrents_query) do
        <<~GQL
          query {
            currentUser {
              id
              email
            }
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

      it 'returns email only for own profile' do
        post '/graphql', params: { query: own_torrents_query }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        # Current user's own email should be visible
        expect(json['data']['currentUser']['email']).to eq(user.email)
        
        # But other users' emails should be nil even though torrents are listed
        torrents_data = json['data']['torrents']['edges'].map { |edge| edge['node'] }
        other_user_torrents = torrents_data.select { |t| t['user']['id'] != user.id.to_s }
        other_user_torrents.each do |torrent|
          expect(torrent['user']['email']).to be_nil
        end
      end
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