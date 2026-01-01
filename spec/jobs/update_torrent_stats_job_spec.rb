require 'rails_helper'

RSpec.describe UpdateTorrentStatsJob, type: :job do
  describe '#perform' do
    let!(:user) { create(:user) }
    let!(:torrent) { create(:torrent, user: user, seeders: 0, leechers: 0) }

    context 'with active seeders and leechers' do
      let!(:seeder1) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 30.minutes.ago) }
      let!(:seeder2) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 15.minutes.ago) }
      let!(:leecher1) { create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 20.minutes.ago) }
      let!(:leecher2) { create(:peer, torrent: torrent, user: user, left: 5000, last_announce: 45.minutes.ago) }

      it 'updates torrent seeders count' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(2)
      end

      it 'updates torrent leechers count' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.leechers).to eq(2)
      end
    end

    context 'with only seeders' do
      let!(:seeder1) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 30.minutes.ago) }
      let!(:seeder2) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 15.minutes.ago) }

      it 'updates seeders to correct count' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(2)
        expect(torrent.leechers).to eq(0)
      end
    end

    context 'with only leechers' do
      let!(:leecher1) { create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 20.minutes.ago) }
      let!(:leecher2) { create(:peer, torrent: torrent, user: user, left: 5000, last_announce: 10.minutes.ago) }

      it 'updates leechers to correct count' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(0)
        expect(torrent.leechers).to eq(2)
      end
    end

    context 'with stale peers (over 1 hour old)' do
      let!(:active_seeder) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 30.minutes.ago) }
      let!(:stale_seeder) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 2.hours.ago) }
      let!(:active_leecher) { create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 15.minutes.ago) }
      let!(:stale_leecher) { create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 90.minutes.ago) }

      it 'only counts active peers (within last hour)' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(1) # Only active_seeder
        expect(torrent.leechers).to eq(1) # Only active_leecher
      end
    end

    context 'with no peers' do
      it 'sets both counts to zero' do
        torrent.update(seeders: 5, leechers: 3)
        
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(0)
        expect(torrent.leechers).to eq(0)
      end
    end

    context 'with invalid torrent ID' do
      it 'returns without error when torrent not found' do
        expect {
          described_class.new.perform('invalid-uuid')
        }.not_to raise_error
      end

      it 'does not perform any updates' do
        expect_any_instance_of(Torrent).not_to receive(:update)
        
        described_class.new.perform('invalid-uuid')
      end
    end

    context 'with nil torrent ID' do
      it 'returns without error' do
        expect {
          described_class.new.perform(nil)
        }.not_to raise_error
      end
    end

    context 'state transitions' do
      it 'correctly updates when leechers become seeders' do
        # Initial state: 1 leecher
        leecher = create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 30.minutes.ago)
        
        described_class.new.perform(torrent.id)
        torrent.reload
        expect(torrent.seeders).to eq(0)
        expect(torrent.leechers).to eq(1)
        
        # Peer completes download
        leecher.update(left: 0, last_announce: Time.current)
        
        described_class.new.perform(torrent.id)
        torrent.reload
        expect(torrent.seeders).to eq(1)
        expect(torrent.leechers).to eq(0)
      end
    end

    context 'with multiple peers from same user' do
      let!(:peer1) { create(:peer, torrent: torrent, user: user, left: 0, last_announce: 30.minutes.ago) }
      let!(:peer2) { create(:peer, torrent: torrent, user: user, left: 1000, last_announce: 20.minutes.ago) }

      it 'counts all peers regardless of user' do
        described_class.new.perform(torrent.id)
        torrent.reload
        
        expect(torrent.seeders).to eq(1)
        expect(torrent.leechers).to eq(1)
      end
    end
  end
end
