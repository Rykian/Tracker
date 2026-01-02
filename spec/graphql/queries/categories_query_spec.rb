require 'rails_helper'

RSpec.describe 'Categories Query', type: :request do
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
