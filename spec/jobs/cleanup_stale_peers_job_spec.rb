require 'rails_helper'

RSpec.describe CleanupStalePeersJob, type: :job do
  describe '#perform' do
    let!(:user) { create(:user) }
    let!(:torrent1) { create(:torrent, user: user) }
    let!(:torrent2) { create(:torrent, user: user) }
    
    context 'with stale peers' do
      let!(:stale_peer1) { create(:peer, torrent: torrent1, user: user, last_announce: 2.hours.ago) }
      let!(:stale_peer2) { create(:peer, torrent: torrent1, user: user, last_announce: 90.minutes.ago) }
      let!(:stale_peer3) { create(:peer, torrent: torrent2, user: user, last_announce: 3.hours.ago) }
      let!(:active_peer) { create(:peer, torrent: torrent1, user: user, last_announce: 30.minutes.ago) }

      it 'removes peers that have not announced in over 1 hour' do
        expect {
          described_class.new.perform
        }.to change(Peer, :count).by(-3)
        
        expect(Peer.exists?(stale_peer1.id)).to be false
        expect(Peer.exists?(stale_peer2.id)).to be false
        expect(Peer.exists?(stale_peer3.id)).to be false
        expect(Peer.exists?(active_peer.id)).to be true
      end

      it 'enqueues stats update jobs for affected torrents' do
        expect {
          described_class.new.perform
        }.to have_enqueued_job(UpdateTorrentStatsJob).with(torrent1.id)
         .and have_enqueued_job(UpdateTorrentStatsJob).with(torrent2.id)
      end
    end

    context 'with no stale peers' do
      let!(:active_peer1) { create(:peer, torrent: torrent1, user: user, last_announce: 30.minutes.ago) }
      let!(:active_peer2) { create(:peer, torrent: torrent1, user: user, last_announce: 45.minutes.ago) }

      it 'does not remove any peers' do
        expect {
          described_class.new.perform
        }.not_to change(Peer, :count)
      end

      it 'does not enqueue any update jobs' do
        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(UpdateTorrentStatsJob)
      end

      it 'logs zero cleanup' do
        expect(Rails.logger).to receive(:info).with(/Cleaned up 0 stale peers/)
        
        described_class.new.perform
      end
    end

    context 'with peer exactly at 1 hour boundary' do
      let!(:boundary_peer) { create(:peer, torrent: torrent1, user: user, last_announce: 59.minutes.ago) }

      it 'does not remove peer within 1 hour' do
        expect {
          described_class.new.perform
        }.not_to change(Peer, :count)
      end
    end

    context 'with mixed stale and active peers on same torrent' do
      let!(:stale_peer) { create(:peer, torrent: torrent1, user: user, last_announce: 2.hours.ago) }
      let!(:active_peer) { create(:peer, torrent: torrent1, user: user, last_announce: 30.minutes.ago) }

      it 'removes only stale peers' do
        expect {
          described_class.new.perform
        }.to change(Peer, :count).by(-1)
        
        expect(Peer.exists?(stale_peer.id)).to be false
        expect(Peer.exists?(active_peer.id)).to be true
      end

      it 'still enqueues stats update for affected torrent' do
        expect {
          described_class.new.perform
        }.to have_enqueued_job(UpdateTorrentStatsJob).with(torrent1.id)
      end
    end
  end
end
