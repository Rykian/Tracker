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
