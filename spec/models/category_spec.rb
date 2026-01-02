# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category do
  describe '.all' do
    it 'returns all categories' do
      expect(described_class.all).to be_a(Hash)
      expect(described_class.all).not_to be_empty
    end

    it 'includes main categories' do
      expect(described_class.all.keys).to include(1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000)
    end
  end

  describe '.ids' do
    it 'returns array of all category IDs' do
      ids = described_class.ids
      expect(ids).to be_an(Array)
      expect(ids).to include(1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000)
    end
  end

  describe '.names' do
    it 'returns array of all category names' do
      names = described_class.names
      expect(names).to be_an(Array)
      expect(names).to include("Movies", "TV", "Audio", "Books", "PC", "Console", "XXX", "Other")
    end
  end

  describe '.name_for' do
    it 'returns name for valid category ID' do
      expect(described_class.name_for(2000)).to eq("Movies")
      expect(described_class.name_for(2040)).to eq("Movies/HD")
      expect(described_class.name_for(5000)).to eq("TV")
    end

    it 'returns nil for invalid ID' do
      expect(described_class.name_for(9999)).to be_nil
    end
  end

  describe '.valid_id?' do
    it 'returns true for valid category ID' do
      expect(described_class.valid_id?(2000)).to be true
      expect(described_class.valid_id?(2040)).to be true
    end

    it 'returns false for invalid category ID' do
      expect(described_class.valid_id?(9999)).to be false
    end
  end
end
