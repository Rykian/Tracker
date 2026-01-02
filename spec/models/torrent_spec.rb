require 'rails_helper'

RSpec.describe Torrent, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:peers).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:torrent) }

    it { should validate_presence_of(:info_hash) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:size) }

    it { should validate_uniqueness_of(:info_hash) }
    it { should validate_length_of(:info_hash).is_equal_to(40) }

    it { should validate_numericality_of(:size).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:seeders).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:leechers).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:completed).only_integer.is_greater_than_or_equal_to(0) }

    describe 'category_id validation' do
      it 'allows valid Torznab category ID' do
        torrent = build(:torrent, category_id: 2000)
        expect(torrent).to be_valid
      end

      it 'allows valid Torznab subcategory ID' do
        torrent = build(:torrent, category_id: 2040)
        expect(torrent).to be_valid
      end

      it 'allows nil category_id' do
        torrent = build(:torrent, category_id: nil)
        expect(torrent).to be_valid
      end

      it 'rejects invalid category_id' do
        torrent = build(:torrent, category_id: 9999)
        expect(torrent).not_to be_valid
        expect(torrent.errors[:category_id]).to include('must be a valid Torznab category ID')
      end
    end
  end

  describe '#magnet_link' do
    let(:torrent) { create(:torrent, name: 'Test Movie', info_hash: 'a' * 40) }

    it 'generates a valid magnet link' do
      magnet = torrent.magnet_link

      expect(magnet).to start_with('magnet:?')
      expect(magnet).to include('xt=urn:btih:')
      expect(magnet).to include(torrent.info_hash)
    end

    it 'includes URL-encoded torrent name' do
      torrent = create(:torrent, name: 'Test Movie 2024')
      magnet = torrent.magnet_link
      encoded_name = ERB::Util.url_encode('Test Movie 2024')

      expect(magnet).to include("dn=#{encoded_name}")
    end

    it 'handles special characters in name' do
      name_with_specials = 'Movie: The "Best" & Greatest!'
      torrent = create(:torrent, name: name_with_specials)
      magnet = torrent.magnet_link
      encoded_name = ERB::Util.url_encode(name_with_specials)

      expect(magnet).to include("dn=#{encoded_name}")
      expect(magnet).to include('xt=urn:btih:')
    end

    context 'with announce URLs' do
      it 'includes tracker URLs' do
        torrent = create(:torrent,
          announce_urls: "http://tracker1.com/announce\nhttp://tracker2.com/announce"
        )
        magnet = torrent.magnet_link

        expect(magnet).to include('&tr=')
        expect(magnet).to include('tracker1.com')
        expect(magnet).to include('tracker2.com')
      end

      it 'URL-encodes tracker URLs' do
        torrent = create(:torrent,
          announce_urls: "http://tracker.com:8080/announce?key=value"
        )
        magnet = torrent.magnet_link

        expect(magnet).to include('&tr=')
        expect(magnet).to include('%3A') # Encoded colon
      end

      it 'encodes tracker URLs with spaces and query params' do
        url = "http://tracker.com/announce?foo=bar baz&x=1&y=2"
        torrent = create(:torrent, announce_urls: url)
        magnet = torrent.magnet_link
        encoded_url = ERB::Util.url_encode(url)

        expect(magnet).to include("&tr=#{encoded_url}")
        expect(encoded_url).to include('bar%20baz') # space encoded as '%20'
        expect(encoded_url).to include('%3F')
      end
    end

    context 'without announce URLs' do
      it 'generates magnet link without trackers' do
        torrent = create(:torrent, announce_urls: nil)
        magnet = torrent.magnet_link

        expect(magnet).to start_with('magnet:?')
        expect(magnet).to include("xt=urn:btih:#{torrent.info_hash}")
        expect(magnet).to include("dn=")
        expect(magnet).not_to include('&tr=')
      end

      it 'handles empty announce URLs string' do
        torrent = create(:torrent, announce_urls: '')
        magnet = torrent.magnet_link

        expect(magnet).not_to include('&tr=')
      end
    end
  end

  describe 'info_hash format' do
    it 'accepts valid 40-character hex string' do
      torrent = build(:torrent, info_hash: 'a' * 40)
      expect(torrent).to be_valid
    end

    it 'rejects info_hash shorter than 40 characters' do
      torrent = build(:torrent, info_hash: 'a' * 39)
      expect(torrent).not_to be_valid
      expect(torrent.errors[:info_hash]).to include('is the wrong length (should be 40 characters)')
    end

    it 'rejects info_hash longer than 40 characters' do
      torrent = build(:torrent, info_hash: 'a' * 41)
      expect(torrent).not_to be_valid
    end
  end

  describe 'uniqueness' do
    it 'prevents duplicate info_hash' do
      existing = create(:torrent, info_hash: 'abc123' + '0' * 34)
      duplicate = build(:torrent, info_hash: 'abc123' + '0' * 34)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:info_hash]).to include('has already been taken')
    end

    it 'allows same name with different info_hash' do
      create(:torrent, name: 'Same Name')
      duplicate_name = build(:torrent, name: 'Same Name')

      expect(duplicate_name).to be_valid
    end
  end

  describe 'stats counters' do
    let(:torrent) { create(:torrent, seeders: 0, leechers: 0, completed: 0) }

    it 'initializes with zero stats' do
      expect(torrent.seeders).to eq(0)
      expect(torrent.leechers).to eq(0)
      expect(torrent.completed).to eq(0)
    end

    it 'allows updating stats' do
      torrent.update(seeders: 5, leechers: 3, completed: 10)

      expect(torrent.seeders).to eq(5)
      expect(torrent.leechers).to eq(3)
      expect(torrent.completed).to eq(10)
    end

    it 'does not allow negative stats' do
      torrent = build(:torrent, seeders: -1)
      expect(torrent).not_to be_valid

      torrent = build(:torrent, leechers: -1)
      expect(torrent).not_to be_valid

      torrent = build(:torrent, completed: -1)
      expect(torrent).not_to be_valid
    end
  end

  describe 'file data' do
    it 'stores files as JSONB array' do
      files = [
        { 'path' => 'movie.mkv', 'length' => 1_000_000 },
        { 'path' => 'subtitles.srt', 'length' => 50_000 }
      ]
      torrent = create(:torrent, files: files)

      expect(torrent.files).to eq(files)
      expect(torrent.files.first['path']).to eq('movie.mkv')
    end

    it 'defaults to empty array' do
      torrent = create(:torrent, files: [])
      torrent.reload

      expect(torrent.files).to eq([])
    end
  end

  describe 'privacy flag' do
    it 'defaults to false' do
      torrent = create(:torrent)
      torrent.reload

      expect(torrent.private).to eq(false)
    end

    it 'can be set to true' do
      torrent = create(:torrent, private: true)

      expect(torrent.private).to eq(true)
    end
  end

  describe 'associations with dependent destroy' do
    let!(:torrent) { create(:torrent) }
    let!(:peer1) { create(:peer, torrent: torrent) }
    let!(:peer2) { create(:peer, torrent: torrent) }

    it 'destroys associated peers when torrent is destroyed' do
      expect {
        torrent.destroy
      }.to change(Peer, :count).by(-2)
    end
  end

  describe 'timestamps' do
    it 'sets created_at on creation' do
      torrent = create(:torrent)
      expect(torrent.created_at).to be_present
    end

    it 'updates updated_at on modification' do
      torrent = create(:torrent)
      original_updated_at = torrent.updated_at

      sleep 0.01 # Ensure time difference
      torrent.update(name: 'Updated Name')

      expect(torrent.updated_at).to be > original_updated_at
    end
  end

  describe '#category_name' do
    it 'returns the category name for a valid category_id' do
      torrent = create(:torrent, category_id: 2000)
      expect(torrent.category_name).to eq("Movies")
    end

    it 'returns the subcategory name for a valid subcategory_id' do
      torrent = create(:torrent, category_id: 2040)
      expect(torrent.category_name).to eq("Movies/HD")
    end

    it 'returns nil when category_id is nil' do
      torrent = create(:torrent, category_id: nil)
      expect(torrent.category_name).to be_nil
    end

    it 'returns nil for an invalid category_id' do
      torrent = build(:torrent, category_id: 9999)
      torrent.save(validate: false) # Skip validation
      expect(torrent.category_name).to be_nil
    end
  end
end
