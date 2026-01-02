# Removes stale peer connections and updates torrent statistics
#
# Purpose:
#   Periodically cleans up peers that haven't announced within the last hour,
#   then refreshes statistics for all affected torrents.
#
# Trigger:
#   - Runs automatically via recurring job schedule (see config/recurring.yml)
#   - Can be manually invoked: CleanupStalePeersJob.perform_later
#
# Behavior:
#   1. Identifies peers with last_announce older than 1 hour
#   2. Collects affected torrent IDs before deletion
#   3. Bulk deletes all stale peers
#   4. Enqueues UpdateTorrentStatsJob for each affected torrent
#   5. Logs cleanup results
#
# Performance:
#   - Single database query to identify stale peers
#   - Bulk deletion for efficiency
#   - Async stats updates to avoid blocking
#
class CleanupStalePeersJob < ApplicationJob
  queue_as :default

  def perform
    # Remove peers that haven't announced in over 1 hour
    stale_peers = Peer.where("last_announce < ?", 1.hour.ago)

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
