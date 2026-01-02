require 'rails_helper'

RSpec.describe Peer, type: :model do
  describe 'associations' do
    it { should belong_to(:torrent) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:peer_id) }
    it { should validate_presence_of(:ip) }
    it { should validate_presence_of(:port) }
    it { should validate_presence_of(:left) }
    it { should validate_presence_of(:last_announce) }

    it { should validate_length_of(:peer_id).is_equal_to(20) }
    it { should validate_numericality_of(:port).is_greater_than(0).is_less_than_or_equal_to(65535) }
    it { should validate_numericality_of(:left).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:uploaded).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:downloaded).is_greater_than_or_equal_to(0) }
    it { should validate_inclusion_of(:event).in_array(%w[started completed stopped]).allow_nil }

    it 'validates IP format' do
      peer = build(:peer, ip: 'invalid')
      expect(peer).not_to be_valid
      expect(peer.errors[:ip]).to be_present
    end
  end

  describe 'scopes' do
    let(:torrent) { create(:torrent) }

    describe '.active' do
      it 'returns peers that announced within the last hour' do
        active_peer = create(:peer, torrent: torrent, last_announce: 30.minutes.ago)
        stale_peer = create(:peer, :stale, torrent: torrent)

        expect(Peer.active).to include(active_peer)
        expect(Peer.active).not_to include(stale_peer)
      end
    end

    describe '.seeders' do
      it 'returns peers with left = 0' do
        seeder = create(:peer, :seeder, torrent: torrent)
        leecher = create(:peer, :leecher, torrent: torrent)

        expect(Peer.seeders).to include(seeder)
        expect(Peer.seeders).not_to include(leecher)
      end
    end

    describe '.leechers' do
      it 'returns peers with left > 0' do
        seeder = create(:peer, :seeder, torrent: torrent)
        leecher = create(:peer, :leecher, torrent: torrent)

        expect(Peer.leechers).to include(leecher)
        expect(Peer.leechers).not_to include(seeder)
      end
    end
  end

  describe '#seeder?' do
    it 'returns true when left is 0' do
      peer = build(:peer, :seeder)
      expect(peer.seeder?).to be true
    end

    it 'returns false when left is greater than 0' do
      peer = build(:peer, :leecher)
      expect(peer.seeder?).to be false
    end
  end

  describe '#leecher?' do
    it 'returns true when left is greater than 0' do
      peer = build(:peer, :leecher)
      expect(peer.leecher?).to be true
    end

    it 'returns false when left is 0' do
      peer = build(:peer, :seeder)
      expect(peer.leecher?).to be false
    end
  end
end
