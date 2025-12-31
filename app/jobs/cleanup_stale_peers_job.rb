class CleanupStalePeersJob < ApplicationJob
  queue_as :default

  def perform
    # Remove peers that haven't announced in over 1 hour
    stale_peers = Peer.where('last_announce < ?', 1.hour.ago)
    
    # Get affected torrent IDs before deletion
    affected_torrent_ids = stale_peers.distinct.pluck(:torrent_id)
    
    # Delete stale peers
    deleted_count = stale_peers.delete_all
    
    # Update stats for affected torrents
    affected_torrent_ids.each do |torrent_id|
      UpdateTorrentStatsJob.perform_later(torrent_id)
    end
    
    Rails.logger.info "Cleaned up #{deleted_count} stale peers, updated #{affected_torrent_ids.size} torrents"
  end
end
