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
                category {
                  id
                  name
                }
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
      edges = json.dig('data', 'torrents', 'edges')
      
      expect(edges).to be_present
      data = edges.map { |edge| edge['node'] }
      
      expect(data.length).to eq(5)
      expect(data[0]['name']).to be_present
      expect(data[0]['infoHash']).to be_present
      expect(data[0]['magnetLink']).to include('magnet:')
      
      # Check category object
      category = data[0]['category']
      expect(category).to be_present
      expect(category).to have_key('id')
      expect(category).to have_key('name')
      expect(category['id']).to be_a(Integer)
      expect(category['name']).to be_a(String)
    end

    it 'returns the magnet link for each torrent' do
      target_torrent = torrents.first

      post '/graphql', params: { query: query }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      node = json.dig('data', 'torrents', 'edges')
        .map { |edge| edge['node'] }
        .find { |torrent| torrent['id'] == target_torrent.id.to_s }

      expect(node).to be_present
      expect(node['magnetLink']).to eq(target_torrent.magnet_link)
    end

    context 'with category filter' do
      before do
        torrents[0].update(category_id: 5000)  # TV parent
        torrents[1].update(category_id: 5010)  # TV/WEB-DL
        torrents[2].update(category_id: 5080)  # TV/Documentary
        other_torrents.each { |t| t.update(category_id: 2000) }  # Movies
      end

      let(:filtered_query) do
        <<~GQL
          query {
            torrents(category: 5000) {
              edges {
                node {
                  id
                  category {
                    id
                    name
                  }
                }
              }
            }
          }
        GQL
      end

      it 'filters torrents by main category and its subcategories' do
        post '/graphql', params: { query: filtered_query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        edges = json['data']['torrents']['edges']
        data = edges.map { |edge| edge['node'] }
        
        expect(data.length).to eq(3)
        expect(data.all? { |t| t.dig('category', 'id') / 1000 == 5 }).to be true
      end
    end

    context 'with exact category filter' do
      before do
        torrents[0].update(category_id: 5000)
        torrents[1].update(category_id: 5010)
        torrents[2].update(category_id: 5040)  # TV/HD
        other_torrents.each { |t| t.update(category_id: 2000) }
      end

      let(:filtered_query) do
        <<~GQL
          query {
            torrents(exactCategory: 5010) {
              edges {
                node {
                  id
                  category {
                    id
                    name
                  }
                }
              }
            }
          }
        GQL
      end

      it 'filters torrents by the exact category only' do
        post '/graphql', params: { query: filtered_query }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        edges = json['data']['torrents']['edges']
        data = edges.map { |edge| edge['node'] }
        
        expect(data.length).to eq(1)
        expect(data.first.dig('category', 'id')).to eq(5010)
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
        data = json.dig('data', 'torrents', 'edges').map { |edge| edge['node'] }
        
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

  describe 'categories query' do
    let(:query) do
      <<~GQL
        query {
          categories {
            id
            name
          }
        }
      GQL
    end

    it 'returns all available categories' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      categories = json['data']['categories']
      
      expect(categories).to be_an(Array)
      expect(categories.length).to eq(67) # Total Torznab categories
      
      # Check some main categories exist
      category_ids = categories.map { |c| c['id'] }
      expect(category_ids).to include(1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000)
    end

    it 'returns category with correct structure' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      movies_category = json['data']['categories'].find { |c| c['id'] == 2000 }
      
      expect(movies_category).to include(
        'id' => 2000,
        'name' => 'Movies'
      )
    end

    it 'includes all subcategories' do
      post '/graphql', params: { query: query }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      categories = json['data']['categories']
      
      # Check Movies subcategories
      movie_subcats = [2010, 2020, 2030, 2040, 2045, 2050, 2060, 2070, 2080]
      category_ids = categories.map { |c| c['id'] }
      
      movie_subcats.each do |subcat_id|
        expect(category_ids).to include(subcat_id)
      end
    end
  end
end