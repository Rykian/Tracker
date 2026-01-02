# Updates torrent statistics by counting active peers
#
# Purpose:
#   Refreshes seeder and leecher counts for a specific torrent based on
#   currently active peers (those who have announced within the last hour).
#
# Trigger:
#   - Automatically enqueued after peer announces (via TrackerController)
#   - Called by CleanupStalePeersJob after removing stale peers
#
# Usage:
#   UpdateTorrentStatsJob.perform_later(torrent_id)
#
# Performance:
#   - Operates on a single torrent at a time
#   - Only counts active peers (optimized query with index on last_announce)
#
class UpdateTorrentStatsJob < ApplicationJob
  queue_as :default

  def perform(torrent_id)
    torrent = Torrent.find_by(id: torrent_id)
    return unless torrent

    # Count active peers only (announced within last hour)
    active_peers = torrent.peers.active

    torrent.update(
      seeders: active_peers.seeders.count,
      leechers: active_peers.leechers.count
    )
  end
end
